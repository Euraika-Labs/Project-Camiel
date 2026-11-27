#!/usr/bin/env python3
"""Build Camiel's original, painted glTF model and transform animations.

The archived 2D Camiel is the design reference. The model uses metres, Y up
and -Z forward. Python's standard library is enough to regenerate the GLB.
"""
import json
import math
from pathlib import Path
import struct
import zlib


ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/characters/camiel/camiel.glb'

CHARCOAL = (.033, .023, .017)
WARM_FUR = (.066, .040, .028)
RUST = (.57, .204, .045)
IVORY = (.94, .855, .69)
GREEN = (.135, .425, .036)
TILE_SIZE = 256
TILES_PER_SIDE = 4
ATLAS_SIZE = TILE_SIZE * TILES_PER_SIDE
TILE_PADDING = 16
TILE_INTERIOR = TILE_SIZE - 2 * TILE_PADDING - 1


def smooth(low, high, value):
    t = min(1.0, max(0.0, (value - low) / (high - low)))
    return t * t * (3.0 - 2.0 * t)


def mix(start, end, amount):
    return tuple(a + (b - a) * amount for a, b in zip(start, end))


def ellipse_mask(x, y, width, height, feather=.15):
    distance = math.hypot(x / width, y / height)
    return 1.0 - smooth(1.0 - feather, 1.0 + feather, distance)


def encode_atlas(paintings):
    """Bake linear paint colours into one padded sRGB PNG for glTF albedo."""
    stride = ATLAS_SIZE * 3 + 1
    raster = bytearray(stride * ATLAS_SIZE)

    def srgb(value):
        encoded = 12.92 * value if value <= .0031308 else 1.055 * value ** (1 / 2.4) - .055
        return round(encoded * 255)

    samples = [min(1.0, max(0.0, (index - TILE_PADDING) / TILE_INTERIOR)) for index in range(TILE_SIZE)]
    for index, (point, paint) in enumerate(paintings):
        left, top = (index % TILES_PER_SIDE) * TILE_SIZE, (index // TILES_PER_SIDE) * TILE_SIZE
        for row, v in enumerate(samples):
            data = bytes(srgb(channel) for u in samples for channel in paint(*point(u, v)))
            offset = (top + row) * stride + 1 + left * 3
            raster[offset:offset + len(data)] = data

    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))

    header = struct.pack('>IIBBBBB', ATLAS_SIZE, ATLAS_SIZE, 8, 2, 0, 0, 0)
    return b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', header) + chunk(b'IDAT', zlib.compress(raster, 9)) + chunk(b'IEND', b'')


def build():
    blob = bytearray()
    paintings = []
    doc = dict(
        asset={'version': '2.0', 'generator': 'Project Camiel authored mesh builder'},
        scene=0,
        scenes=[{'nodes': [0]}],
        nodes=[{'name': 'CamielModel', 'children': []}],
        meshes=[], materials=[], bufferViews=[], accessors=[], animations=[],
    )

    def buffer_view(data):
        blob.extend(b'\0' * (-len(blob) % 4))
        offset = len(blob)
        blob.extend(data)
        view = len(doc['bufferViews'])
        doc['bufferViews'].append(dict(buffer=0, byteOffset=offset, byteLength=len(data)))
        return view

    def accessor(values, kind, component=5126):
        width = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4}[kind]
        rows = [[value] for value in values] if width == 1 else values
        flat = [value for row in rows for value in row]
        code = {5123: 'H', 5126: 'f'}[component]
        view = buffer_view(struct.pack(f'<{len(flat)}{code}', *flat))
        index = len(doc['accessors'])
        doc['accessors'].append(dict(
            bufferView=view, componentType=component, count=len(rows), type=kind,
            min=[min(row[i] for row in rows) for i in range(width)],
            max=[max(row[i] for row in rows) for i in range(width)],
        ))
        return index

    def material(name, rgb=(1, 1, 1), roughness=.84, double_sided=False, painted=False):
        index = len(doc['materials'])
        pbr = dict(baseColorFactor=[*rgb, 1], metallicFactor=0, roughnessFactor=roughness)
        if painted:
            pbr['baseColorTexture'] = {'index': 0}
        doc['materials'].append(dict(
            name=name, doubleSided=double_sided,
            pbrMetallicRoughness=pbr,
        ))
        return index

    fur = material('Velvet tricolour coat', painted=True)
    eyes = material('Amber eyes', roughness=.45, painted=True)
    nose = material('Soft black nose', (.018, .011, .009), .4)
    glint = material('Eye catchlights', (.98, .94, .83), .56)
    tongue = material('Tongue', (.55, .13, .16), .64)
    cloth = material('Green cotton bandana', roughness=.94, double_sided=True, painted=True)
    knot = material('Green cotton knot', (.094, .30, .024), .94)

    def node(name, parent=0, pos=(0, 0, 0), rotation=None):
        index = len(doc['nodes'])
        entry = dict(name=name, translation=list(pos), children=[])
        if rotation is not None:
            entry['rotation'] = rotation
        doc['nodes'].append(entry)
        doc['nodes'][parent]['children'].append(index)
        return index

    def surface(name, point, mat, parent, pos, *, rows, sides, paint=None, caps=(False, False)):
        vertices, normals, indices = [], [], []
        du, dv = .15 / sides, .15 / rows
        for row in range(rows + 1):
            v = row / rows
            # At a collapsed pole, use the neighbouring surface for its normal.
            sample_v = min(1.0 - dv, max(dv, v))
            for column in range(sides + 1):
                u = column / sides
                vertices.append(point(u, v))
                left, right = point(u - du, sample_v), point(u + du, sample_v)
                top, bottom = point(u, sample_v - dv), point(u, sample_v + dv)
                ax, ay, az = (b - a for a, b in zip(left, right))
                bx, by, bz = (b - a for a, b in zip(top, bottom))
                normal = (ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx)
                length = math.hypot(*normal)
                normals.append(tuple(value / length for value in normal))
        for row in range(rows):
            for column in range(sides):
                a = row * (sides + 1) + column
                b = a + sides + 1
                if row > 0 or not caps[0]:
                    indices.extend((a, a + 1, b))
                if row < rows - 1 or not caps[1]:
                    indices.extend((a + 1, b + 1, b))
        attributes = {'POSITION': accessor(vertices, 'VEC3'), 'NORMAL': accessor(normals, 'VEC3')}
        if paint:
            tile = len(paintings)
            if tile >= TILES_PER_SIDE ** 2:
                raise ValueError('Camiel paint atlas is full')
            paintings.append((point, paint))
            left = (tile % TILES_PER_SIDE) * TILE_SIZE + TILE_PADDING + .5
            top = (tile // TILES_PER_SIDE) * TILE_SIZE + TILE_PADDING + .5
            attributes['TEXCOORD_0'] = accessor([
                ((left + column * TILE_INTERIOR / sides) / ATLAS_SIZE,
                 (top + row * TILE_INTERIOR / rows) / ATLAS_SIZE)
                for row in range(rows + 1) for column in range(sides + 1)
            ], 'VEC2')
        index = node(name, parent, pos)
        doc['nodes'][index]['mesh'] = len(doc['meshes'])
        doc['meshes'].append(dict(name=name, primitives=[dict(
            attributes=attributes, indices=accessor(indices, 'SCALAR', 5123), material=mat,
        )]))
        return index

    def oval(name, pos, radii, mat, parent=0, *, paint=None, shape=None, rows=16, sides=28):
        rx, ry, rz = radii

        def point(u, v):
            phi, theta = math.pi * v, math.tau * u
            span = math.sin(phi)
            x, y, z = rx * span * math.cos(theta), ry * math.cos(phi), rz * span * math.sin(theta)
            return shape(x, y, z) if shape else (x, y, z)

        return surface(name, point, mat, parent, pos, rows=rows, sides=sides, paint=paint, caps=(True, True))

    def loft(name, parent, sections, paint, *, rows=30, sides=28):
        """Smoothly join elliptical cross sections from top to bottom."""
        end = len(sections) - 1

        def point(u, v):
            span = v * end
            index = min(int(span), end - 1)
            t = span - index
            before, start, finish, after = (
                sections[max(0, index - 1)], sections[index],
                sections[index + 1], sections[min(end, index + 2)],
            )
            # Catmull-Rom interpolation keeps the profile and its tangent continuous.
            x, y, z, rx, rz = (
                b + .5 * t * (c - a + t * (2*a - 5*b + 4*c - d + t * (3*b - a - 3*c + d)))
                for a, b, c, d in zip(before, start, finish, after)
            )
            angle = math.tau * u
            return x + max(rx, 0) * math.cos(angle), y, z + max(rz, 0) * math.sin(angle)

        return surface(name, point, fur, parent, (0, 0, 0), rows=rows, sides=sides,
                       paint=paint, caps=(True, True))

    def body_colour(x, y, z):
        coat = mix(CHARCOAL, WARM_FUR, .28 + .36 * smooth(-.22, .1, -y))
        bib_width = .122 + .024 * smooth(-.14, .14, y)
        bib = smooth(.128, .267, -z) * smooth(-.018, .012, bib_width - abs(x))
        coat = mix(coat, RUST, .30 * smooth(.145, .207, abs(x)) * smooth(.105, .238, -z))
        return mix(coat, IVORY, bib)

    body = node('Torso', pos=(0, .555, .052))
    oval('Coat', (0, 0, 0), (.237, .233, .391), fur, body,
         paint=body_colour, shape=lambda x, y, z: (x * (1.0 - .20 * z), y - .045 * z, z),
         rows=30, sides=48)

    head = node('Head', body, (0, .358, -.259))

    def head_colour(x, y, z):
        coat = mix(CHARCOAL, WARM_FUR, .22 + .44 * smooth(-.16, .08, -y))
        brow = ellipse_mask(abs(x) - .113, y - .087 - .14 * (abs(x) - .113), .053, .025, .24)
        cheek = ellipse_mask(abs(x) - .145, y + .071 - .26 * (abs(x) - .145), .080, .063, .20)
        coat = mix(coat, RUST, max(brow, cheek) * smooth(.090, .155, -z))
        width = .030 + .038 * smooth(.045, .15, -y) - .012 * smooth(.164, .231, y)
        edge = width - abs(x - .007 * math.sin(13.0 * y))
        return mix(coat, IVORY, smooth(-.005, .006, edge) * smooth(.031, .103, -z))

    oval('HeadCoat', (0, 0, 0), (.246, .235, .216), fur, head,
         paint=head_colour, shape=lambda x, y, z: (x * (1.0 - .31 * y), y, z * (1.0 - .36 * y)),
         rows=28, sides=48)

    def quat_x(angle):
        return [math.sin(angle / 2), 0, 0, math.cos(angle / 2)]

    def quat_y(angle):
        return [0, math.sin(angle / 2), 0, math.cos(angle / 2)]

    def quat_z(angle):
        return [0, 0, math.sin(angle / 2), math.cos(angle / 2)]

    def eye_colour(x, y, z):
        iris = ellipse_mask(x - .001, y + .001, .037, .043, .08)
        iris_tone = mix((.09, .029, .012), (.47, .190, .046), smooth(-.012, .038, -y))
        pupil = ellipse_mask(x - .001, y - .005, .021, .030, .10)
        pupil_tone = (.011, .006, .004)
        pigment = smooth(.003, .018, -z)
        return mix((.748, .696, .604), mix(iris_tone, pupil_tone, pupil), iris * pigment)

    def ear_colour(x, y, z):
        lining = ellipse_mask(x, y + .20, .061, .095, .45) * smooth(.017, .045, -z)
        return mix(mix(CHARCOAL, WARM_FUR, .22), (.139, .069, .044), .55 * lining)

    ears, eyelids = [], []
    for side, label in ((-1, 'Left'), (1, 'Right')):
        eye = node(label + 'Eye', head, (side * .114, .026, -.182), quat_y(-side * .34))
        eyelids.append(eye)
        oval(label + 'AmberEye', (0, 0, 0), (.051, .043, .029), eyes, eye, paint=eye_colour,
             rows=18, sides=30)
        oval(label + 'EyeGlint', (-.010, .015, -.026), (.009, .010, .005), glint, eye, rows=8, sides=12)
        oval(label + 'EyeGlintSmall', (.013, -.014, -.026), (.004, .004, .003), glint, eye, rows=6, sides=10)

        ear = node(label + 'Ear', head, (side * .208, .118, .004))
        ears.append(ear)
        extra_drop = .014 if side < 0 else 0
        loft(label + 'FloppyEar', ear, [
            (0, .033, .018, 0, 0),
            (side * .018, .003, .014, .063, .066),
            (side * .046, -.073, .012, .084, .080),
            (side * .074, -.147, -.001, .076, .075),
            (side * .069, -.227, -.021, .058, .059),
            (side * .046, -.291 - extra_drop, -.029, .039, .039),
            (side * .029, -.320 - extra_drop, -.022, 0, 0),
        ], ear_colour, rows=30, sides=32)

    def muzzle_colour(x, y, z):
        width = min(1.0, abs(x) / .138)
        smile = -.042 + .024 * width ** 1.7
        thickness = .007 + .013 * (1.0 - width) ** 2
        lip = ((1.0 - smooth(thickness - .003, thickness + .003, abs(y - smile)))
               * smooth(.014, .043, -z) * (1.0 - smooth(.126, .146, abs(x))))
        coat = mix((.79, .638, .46), IVORY, smooth(-.080, .024, y))
        return mix(coat, (.052, .023, .017), lip)

    oval('Muzzle', (0, -.080, -.218), (.152, .096, .128), fur, head, paint=muzzle_colour,
         shape=lambda x, y, z: (x * (1 + .88 * y), y, z + .009 * math.exp(-(x/.037)**2)),
         rows=24, sides=44)
    oval('Nose', (0, -.032, -.335), (.073, .047, .035), nose, head,
         shape=lambda x, y, z: (x * (1 + 6.5 * y), y, z))
    oval('Tongue', (.022, -.138, -.315), (.030, .031, .039), tongue, head,
         shape=lambda x, y, z: (x - .22*y, y, z + .25*y), rows=18, sides=26)

    # A rounded, folded neck band and a curved cloth panel with a dyed paw motif.
    oval('BandanaWrap', (0, .765, -.149), (.218, .046, .205), cloth, paint=lambda x, y, z: mix(
        (.078, .268, .027), GREEN, smooth(-.039, .038, y)))
    oval('BandanaKnot', (.010, .788, .058), (.069, .052, .046), knot, shape=lambda x, y, z: (x, y + .24*x, z))
    oval('BandanaEndLeft', (-.048, .739, .076), (.046, .089, .020), knot,
         shape=lambda x, y, z: (x + .42*y, y, z - .24*y))
    oval('BandanaEndRight', (.060, .745, .079), (.039, .077, .018), knot,
         shape=lambda x, y, z: (x - .43*y, y, z - .28*y))

    def panel_width(v):
        return .189 * (1.0 - v) ** .88

    def bandana(u, v):
        cross = 2*u - 1
        x = panel_width(v) * cross + .017 * v * v
        y = .775 - .259 * v - .019 * (1 - cross*cross) * (1-v)
        z = -.344 - .045 * math.sin(math.pi * .78 * v) + .100 * cross*cross * (1-v)
        z += .009 * math.sin(7.5 * cross + 2.0*v) * (1 - v)
        return x, y, z

    def bandana_colour(x, y, z):
        v = (0.775 - y) / .259
        cross = abs(x - .017*v*v) / max(.010, panel_width(min(1.0, max(0.0, v))))
        base = mix((.065, .264, .020), GREEN, .50 + .45 * math.sin(x*20.0 + v*3.4))
        trim = smooth(.80, .96, cross) * smooth(.012, .055, v)
        trimmed = mix(base, (.222, .480, .064), .68 * trim)
        paw = ellipse_mask(x - .005, y - .629, .034, .024, .20)
        for toe_x, toe_y in ((-.035, .663), (-.011, .681), (.017, .680), (.042, .661)):
            paw = max(paw, ellipse_mask(x - toe_x, y - toe_y, .012, .015, .18))
        return mix(trimmed, IVORY, paw)

    surface('Bandana', bandana, cloth, 0, (0, 0, 0), rows=20, sides=32, paint=bandana_colour,
            caps=(False, True))

    def paw_colour(x, y, z):
        toes = math.exp(-((abs(x) - .034) / .008)**2)
        grooves = .17 * toes * smooth(.080, .131, -z) * smooth(.384, .447, -y)
        sock = smooth(.237, .311, -y + .18 * -z - .27 * abs(x))
        paw = smooth(.339, .393, -y + .19 * -z)
        coat = mix(mix(WARM_FUR, CHARCOAL, smooth(-.24, .12, z)), RUST, sock)
        return mix(coat, mix(IVORY, (.57, .394, .235), grooves), paw)

    legs = []
    for name, x, z in (
        ('FrontLeft', -.145, -.239), ('FrontRight', .145, -.239),
        ('RearLeft', -.158, .278), ('RearRight', .158, .278),
    ):
        front = name.startswith('Front')
        leg = node(name, pos=(x, .479, z))
        legs.append(leg)
        loft(name + 'Coat', leg, [
            (0, .145, .014, 0, 0),
            (0, .064, .010, .088 if front else .110, .107 if front else .136),
            (0, -.092, -.003 if front else -.020, .086 if front else .103, .104 if front else .123),
            (0, -.215, .007 if front else .038, .074, .081 if front else .093),
            (0, -.325, -.012 if front else .035, .067, .071),
            (0, -.403, -.040 if front else -.016, .096, .112),
            (0, -.448, -.042 if front else -.022, .092, .106),
            (0, -.474, -.031 if front else -.011, .059, .069),
            (0, -.480, -.021 if front else -.003, 0, 0),
        ], paw_colour, rows=32, sides=32)

    tail = node('Tail', pos=(0, .64, .359))

    def tail_point(u, v):
        angle = math.tau * u
        # The base sits inside the rump. The tip curls up and tapers to a rounded point.
        radius = .088 * math.sqrt(1 - v)
        y = -.065 * math.sin(math.pi * v) + .234 * v * v
        z = .446 * v - .102 * v ** 3
        return radius * math.cos(angle) + .101 * v * v, y + radius * math.sin(angle), z

    def tail_colour(x, y, z):
        return mix(mix(CHARCOAL, WARM_FUR, .41), IVORY, smooth(.098, .150, y))

    surface('TailFur', tail_point, fur, tail, (0, 0, 0), rows=28, sides=28, paint=tail_colour,
            caps=(False, True))

    def animation(name, duration, channels, samples):
        anim = dict(name=name, samplers=[], channels=[])
        clock = accessor([duration * t for t in samples], 'SCALAR')
        for target, path, value_at in channels:
            sampler = len(anim['samplers'])
            values = [value_at(t) for t in samples]
            output = accessor(values, 'VEC4' if path == 'rotation' else 'VEC3')
            anim['samplers'].append(dict(input=clock, output=output, interpolation='LINEAR'))
            anim['channels'].append(dict(sampler=sampler, target=dict(node=target, path=path)))
        doc['animations'].append(anim)

    # Key every animated transform in every clip so a blend always restores the pose.
    for name, duration in (('idle', 3.2), ('walk', .62), ('jump', .70)):
        walking, jumping = name == 'walk', name == 'jump'

        def head_pose(t):
            pitch = -.14 if jumping else .044 * math.sin(math.tau * t)
            roll = .064 * math.sin(math.tau * t) if name == 'idle' else 0.0
            sin_pitch, cos_pitch = math.sin(pitch / 2), math.cos(pitch / 2)
            sin_roll, cos_roll = math.sin(roll / 2), math.cos(roll / 2)
            return [sin_pitch * cos_roll, -sin_pitch * sin_roll, cos_pitch * sin_roll, cos_pitch * cos_roll]

        channels = [
            (body, 'translation', lambda t: [0, .555 + (.013 if walking else .009) * math.sin(math.tau*t), .052]),
            (head, 'rotation', head_pose),
            (tail, 'rotation', lambda t: quat_y((.29 if jumping else .55) * math.sin(math.tau*t))),
        ]
        for index, leg in enumerate(legs):
            phase = 1 if index in (0, 3) else -1
            rest = doc['nodes'][leg]['translation']

            def stride(t, phase=phase, front=index < 2):
                if walking:
                    return phase * .47 * math.sin(math.tau * t)
                if jumping:
                    return (-.46 if front else .40) * (.61 + .39 * math.sin(math.pi * t))
                return 0.0

            def step(t, phase=phase, rest=rest):
                height = .052 * max(0.0, phase * math.cos(math.tau*t)) if walking else 0.0
                return [rest[0], rest[1] + height, rest[2]]

            channels.extend(((leg, 'rotation', lambda t, stride=stride: quat_x(stride(t))),
                             (leg, 'translation', step)))
        for index, ear in enumerate(ears):
            side = -1 if index == 0 else 1
            channels.append((ear, 'rotation', lambda t, side=side: quat_z(
                side * ((.15 if jumping else .072 if walking else .026) * math.sin(math.tau*t - .8)))))

        def blink(t):
            closure = .91 * max(0.0, 1 - abs(t - .59)/.032) if name == 'idle' else 0.0
            return [1.0, 1.0 - closure, 1.0]

        channels.extend((eye, 'scale', blink) for eye in eyelids)
        samples = [i/16 for i in range(17)]
        if name == 'idle':
            samples = sorted([*samples, .558, .579, .590, .603, .622])
        animation(name, duration, channels, samples)

    doc['images'] = [dict(name='CamielPaint', mimeType='image/png', bufferView=buffer_view(encode_atlas(paintings)))]
    doc['textures'] = [dict(source=0, sampler=0)]
    doc['samplers'] = [dict(magFilter=9729, minFilter=9987, wrapS=33071, wrapT=33071)]
    doc['buffers'] = [{'byteLength': len(blob)}]
    doc['extras'] = dict(
        reference_tag='archive/2d-alpha-v0.0.3',
        reference_path='assets/camiel/animations/idle_right/camiel_idle_right_01.png',
        design='Tricolour Bernese puppy with floppy ears, ivory blaze and green paw-print bandana',
        source='Original authored geometry, paint and animations. No external model or textures.',
        axes='Y up, -Z forward, metres',
    )
    encoded = json.dumps(doc, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    blob.extend(b'\0' * (-len(blob) % 4))
    length = 28 + len(encoded) + len(blob)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(
        struct.pack('<4sII', b'glTF', 2, length) + struct.pack('<I4s', len(encoded), b'JSON')
        + encoded + struct.pack('<I4s', len(blob), b'BIN\0') + blob
    )
    print(f'Built {OUT.relative_to(ROOT)}: {len(doc["meshes"])} meshes, {len(doc["animations"])} clips, {length} bytes')


if __name__ == '__main__':
    build()
