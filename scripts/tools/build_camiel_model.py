#!/usr/bin/env python3
"""Build Camiel's authored, texture-free glTF mesh and transform animation rig.

Design reference: archive/2d-alpha-v0.0.3, assets/camiel/animations/
idle_right/camiel_idle_right_01.png. Metres; Y up; nose points along -Z.
No third-party assets or packages. Regenerate with python3 scripts/tools/build_camiel_model.py.
The GLB is checked in so neither Python nor a modelling tool is needed at runtime.
"""
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'assets/characters/camiel/camiel.glb'


def build():
    blob = bytearray()
    doc = dict(asset={'version': '2.0', 'generator': 'Project Camiel authored mesh builder'},
               scene=0, scenes=[{'nodes': [0]}], nodes=[{'name': 'CamielModel', 'children': []}],
               meshes=[], materials=[], bufferViews=[], accessors=[], animations=[])

    def accessor(values, kind, component=5126):
        width = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4}[kind]
        rows = [[v] if width == 1 else v for v in values]
        while len(blob) % 4:
            blob.append(0)
        offset = len(blob)
        flat = [c for row in rows for c in row]
        blob.extend(struct.pack('<' + ('f' if component == 5126 else 'I') * len(flat), *flat))
        view = len(doc['bufferViews'])
        doc['bufferViews'].append(dict(buffer=0, byteOffset=offset, byteLength=len(blob)-offset))
        idx = len(doc['accessors'])
        doc['accessors'].append(dict(bufferView=view, componentType=component, count=len(rows), type=kind,
                                     min=[min(r[i] for r in rows) for i in range(width)],
                                     max=[max(r[i] for r in rows) for i in range(width)]))
        return idx

    def material(name, rgb, roughness=0.85):
        idx = len(doc['materials'])
        doc['materials'].append(dict(name=name, pbrMetallicRoughness=dict(
            baseColorFactor=[*rgb, 1], metallicFactor=0, roughnessFactor=roughness)))
        return idx

    black = material('Warm charcoal fur', [.065, .048, .041])
    rust = material('Rust cheeks and socks', [.64, .25, .055])
    cream = material('Ivory blaze chest and paws', [.93, .89, .77])
    green = material('Camiel green bandana', [.25, .48, .025])
    nose_mat = material('Soft black nose', [.012, .009, .008], .35)
    eye_mat = material('Warm amber eyes', [.25, .095, .018], .3)
    pupil = material('Pupils', [.009, .006, .005], .2)
    pink = material('Tongue', [.68, .25, .28])

    def node(name, parent=0, pos=(0,0,0), rotation=None):
        idx = len(doc['nodes'])
        n = dict(name=name, translation=list(pos), children=[])
        if rotation:
            n['rotation'] = rotation
        doc['nodes'].append(n)
        doc['nodes'][parent].setdefault('children', []).append(idx)
        return idx

    def mesh(name, vertices, normals, indices, mat, parent=0, pos=(0,0,0)):
        idx = node(name, parent, pos)
        doc['nodes'][idx]['mesh'] = len(doc['meshes'])
        attributes = {'POSITION': accessor(vertices, 'VEC3'), 'NORMAL': accessor(normals, 'VEC3')}
        groups = {}
        for start in range(0, len(indices), 3):
            triangle = indices[start:start+3]
            centre = [sum(vertices[v][axis] for v in triangle)/3 for axis in range(3)]
            surface = mat(centre) if callable(mat) else mat
            groups.setdefault(surface, []).extend(triangle)
        doc['meshes'].append(dict(name=name, primitives=[dict(attributes=attributes,
            indices=accessor(tris, 'SCALAR', 5125), material=surface) for surface,tris in groups.items()]))
        return idx

    def oval(name, pos, radius, mat, parent=0, taper=0, rings=12, sides=20):
        vertices, normals, indices = [], [], []
        for j in range(rings+1):
            phi = math.pi*j/rings
            y = math.cos(phi)
            swell = 1 + taper*y
            for i in range(sides+1):
                theta = 2*math.pi*i/sides
                x, z = math.sin(phi)*math.cos(theta), math.sin(phi)*math.sin(theta)
                vertices.append([x*radius[0]*swell, y*radius[1], z*radius[2]*swell])
                n = [x/radius[0], y/radius[1], z/radius[2]]
                length = math.sqrt(sum(v*v for v in n))
                normals.append([v/length for v in n])
        for j in range(rings):
            for i in range(sides):
                a=j*(sides+1)+i; b=a+sides+1
                indices.extend([a, a+1, b, a+1, b+1, b])
        return mesh(name, vertices, normals, indices, mat, parent, pos)

    body = node('Torso', pos=(0,.59,.04))
    oval('Coat', (0,0,0), (.235,.25,.365), black, body, -.1)
    oval('WhiteChest', (0,.015,-.267), (.17,.225,.09), cream, body)
    head = node('Head', body, (0,.35,-.235))
    def head_markings(p):
        x,y,z=p
        if z < -.10 and abs(x) < (.034 if y > -.04 else .065):
            return cream
        if z < -.11 and -.13 < y < -.025 and abs(x) > .08:
            return rust
        return black
    oval('HeadCoat', (0,0,0), (.235,.235,.21), head_markings, head, rings=24,sides=48)
    for side in (-1,1):
        s = 'Left' if side < 0 else 'Right'
        oval(s+'Cheek', (side*.13,-.06,-.16), (.087,.075,.082), rust, head)
        oval(s+'Brow', (side*.12,.10,-.17), (.062,.029,.026), rust, head)
        oval(s+'EyeWhite', (side*.119,.045,-.182), (.046,.052,.033), cream, head)
        oval(s+'Eye', (side*.122,.047,-.207), (.034,.04,.019), eye_mat, head)
        oval(s+'Pupil', (side*.121,.048,-.222), (.019,.027,.008), pupil, head)
        oval(s+'EyeGlint', (side*.11,.062,-.229), (.008,.009,.004), cream, head, rings=8, sides=12)
        ear = node(s+'Ear', head, (side*.205,.105,.01))
        oval(s+'FloppyEar', (side*.025,-.17,.015), (.078,.205,.12), black, ear, -.28)
    oval('LowerJaw', (0,-.147,-.19), (.115,.047,.13), cream, head)
    oval('Mouth', (0,-.117,-.236), (.116,.025,.101), nose_mat, head)
    oval('Muzzle', (0,-.068,-.232), (.133,.068,.134), cream, head)
    oval('Nose', (0,-.033,-.342), (.067,.045,.033), nose_mat, head, -.22)
    oval('Tongue', (.025,-.149,-.281), (.033,.016,.041), pink, head)

    # A tailored triangular scarf, including a rear knot: recognisable from the follow camera.
    vertices = [(-.192,.80,-.361),(.192,.80,-.361),(0,.51,-.393),
                (-.192,.80,-.344),(.192,.80,-.344),(0,.51,-.376)]
    mesh('Bandana', vertices, [(0,.28,-.96)]*3+[(0,-.28,.96)]*3,
         [0,1,2,3,5,4,0,1,4,0,4,3,1,2,5,1,5,4,2,0,3,2,3,5], green)
    oval('ScarfCollar', (0,.79,-.155), (.236,.045,.196), green)
    oval('ScarfKnot', (0,.81,.035), (.06,.055,.052), green)
    oval('ScarfEndLeft', (-.054,.754,.057), (.038,.105,.018), green)
    oval('ScarfEndRight', (.047,.765,.061), (.033,.089,.019), green)
    # Ivory paw emblem inset on the front of the bandana.
    oval('ScarfPawPad', (0,.651,-.385), (.038,.032,.008), cream, rings=8,sides=12)
    for i, (x,y) in enumerate([(-.042,.69),(-.014,.71),(.016,.71),(.043,.69)]):
        oval('ScarfPawToe'+str(i),(x,y,-.38),(.012,.015,.009),cream,rings=8,sides=12)

    legs=[]
    for name,x,z in [('FrontLeft',-.16,-.21),('FrontRight',.16,-.21),
                     ('RearLeft',-.16,.28),('RearRight',.16,.28)]:
        leg = node(name, pos=(x,.49,z)); legs.append(leg)
        oval(name+'Upper',(0,-.11,0),(.091,.174,.101),black,leg,.15)
        oval(name+'Sock',(0,-.295,-.004),(.067,.12,.072),rust,leg)
        oval(name+'Paw',(0,-.432,-.025),(.084,.057,.115),cream,leg)
        for i in (-1,0,1):
            oval(name+'Toe'+str(i),(i*.04,-.442,-.1),(.025,.037,.032),cream,leg,rings=8,sides=12)

    tail=node('Tail',pos=(0,.69,.335))
    # Swept curved tail: one mesh with a white tip, rather than linked primitive nodes.
    vertices=[]; normals=[]; indices=[]
    for j in range(13):
        t=j/12; y=.24*t*t; z=.33*t
        r=.072*(1-t*.87)
        for i in range(13):
            a=2*math.pi*i/12
            vertices.append([r*math.cos(a),y+r*math.sin(a),z])
            normals.append([math.cos(a),math.sin(a),0])
    for j in range(12):
        for i in range(12):
            a=j*13+i; b=a+13
            indices.extend([a,a+1,b,a+1,b+1,b])
    mesh('TailFur',vertices,normals,indices,black,tail)
    oval('WhiteTailTip',(0,.218,.318),(.025,.04,.035),cream,tail)

    def quat_x(a): return [math.sin(a/2),0,0,math.cos(a/2)]
    def quat_y(a): return [0,math.sin(a/2),0,math.cos(a/2)]
    def animation(name, duration, channels):
        anim=dict(name=name,samplers=[],channels=[])
        times=[duration*i/8 for i in range(9)]
        clock=accessor(times,'SCALAR')
        for target,path,fn in channels:
            sampler=len(anim['samplers'])
            output=accessor([fn(i/8) for i in range(9)],'VEC4' if path=='rotation' else 'VEC3')
            anim['samplers'].append(dict(input=clock,output=output,interpolation='LINEAR'))
            anim['channels'].append(dict(sampler=sampler,target=dict(node=target,path=path)))
        doc['animations'].append(anim)

    # Every clip keys every animated transform, so landing and walk->idle cannot retain a tuck.
    for name,duration in [('idle',2.4),('walk',.65),('jump',.7)]:
        channels=[]
        amplitude=.035 if name=='walk' else .018
        channels.append((body,'translation',lambda t,a=amplitude: [0,.59+a*math.sin(t*2*math.pi),.04]))
        channels.append((head,'rotation',lambda t,n=name: quat_x(-.08 if n=='jump' else .025*math.sin(t*2*math.pi))))
        channels.append((tail,'rotation',lambda t,n=name: quat_y((.16 if n=='jump' else .32)*math.sin(t*2*math.pi))))
        for i,leg in enumerate(legs):
            phase=1 if i in (0,3) else -1
            channels.append((leg,'rotation',lambda t,p=phase,n=name,i=i: quat_x(
                p*.55*math.sin(t*2*math.pi) if n=='walk' else
                ((-.4 if i<2 else .45)*(.75+.25*math.sin(math.pi*t))) if n=='jump' else 0)))
        animation(name,duration,channels)

    doc['buffers']=[{'byteLength':len(blob)}]
    metadata={'reference_tag':'archive/2d-alpha-v0.0.3',
              'reference_path':'assets/camiel/animations/idle_right/camiel_idle_right_01.png',
              'design':'Tricolour Bernese puppy, ivory blaze/chest/paws, rust eyebrows/socks, green scarf',
              'source':'Original authored mesh; deterministic Python generator; no external model license',
              'axes':'Y up, -Z forward, metres', 'animations':['idle','walk','jump']}
    doc['extras']=metadata
    encoded=json.dumps(doc,separators=(',',':')).encode()
    encoded+=b' '*((-len(encoded))%4)
    blob+=b'\0'*((-len(blob))%4)
    length=12+8+len(encoded)+8+len(blob)
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_bytes(struct.pack('<4sII',b'glTF',2,length)+struct.pack('<I4s',len(encoded),b'JSON')+
                    encoded+struct.pack('<I4s',len(blob),b'BIN\0')+blob)
    print(f'Built {OUT.relative_to(ROOT)}: {len(doc["meshes"])} meshes, {len(doc["animations"])} clips, {length} bytes')


if __name__=='__main__':
    build()
