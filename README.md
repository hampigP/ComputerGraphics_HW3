# ComputerGraphics_HW3
[DEMO Video](https://youtu.be/fWdH75_qadg)

## Model Matrix (GameObject::localToWorld)

- 平移 (Transition)
- 旋轉 (Rotation X/Y/Z)
- 縮放 (Scale)

組合 4X4 同質座標矩陣

使用的程式碼

```
Matrix4 localToWorld() {
    Matrix4 S  = Matrix4.Scale(transform.scale);
    Matrix4 Rz = Matrix4.RotZ(transform.rotation.z);
    Matrix4 Rx = Matrix4.RotX(transform.rotation.x);
    Matrix4 Ry = Matrix4.RotY(transform.rotation.y);
    Matrix4 T  = Matrix4.Trans(transform.position);

    return T.mult(Ry).mult(Rx).mult(Rz).mult(S);
}
```

## View Matrix (Camera::setPositionOrientation)

採用 LookAt 概念：

- forward = normalize (lookat - position)
- right = normalize (forward X up)
- up = right X forward

使用的程式碼

```
void setPositionOrientation(Vector3 pos, Vector3 lookat) {
    Vector3 up = new Vector3(0, 1, 0);
    Vector3 f = Vector3.sub(lookat, pos).normalized();
    Vector3 s = Vector3.cross(f, up).normalized();
    Vector3 u = Vector3.cross(s, f);

    Matrix4 view = Matrix4.Identity();
    view.m[0] = s.x; view.m[1] = s.y; view.m[2] = s.z;
    view.m[4] = u.x; view.m[5] = u.y; view.m[6] = u.z;
    view.m[8] = -f.x; view.m[9] = -f.y; view.m[10] = -f.z;

    view.m[3]  = -Vector3.dot(s, pos);
    view.m[7]  = -Vector3.dot(u, pos);
    view.m[11] =  Vector3.dot(f, pos);

    worldView = view;
}
```

## Projection Matrix (Camera::setSize)

利用 FOV 與螢幕比例建立 Perspective Projection Matrix

使用的程式碼

```
void setSize(int w, int h, float n, float f) {
    float aspect = (float)w / h;
    float fovRad = radians(GH_FOV);
    float fy = 1 / tan(fovRad * 0.5);

    Matrix4 p = Matrix4.Zero();
    p.m[0]  = fy / aspect;
    p.m[5]  = fy;
    p.m[10] = (f + n) / (n - f);
    p.m[11] = (2 * f * n) / (n - f);
    p.m[14] = -1;

    projection = p;
}
```

## 深度計算 (util::getDepth)

使用三角形的重心座標 (Barycentric) 差值計算 Z 值

使用的程式碼

```
public float getDepth(float x, float y, Vector3[] v) {
    Vector3 A = v[0], B = v[1], C = v[2];
    float denom = (B.y - C.y)*(A.x - C.x) + (C.x - B.x)*(A.y - C.y);

    float w1 = ((B.y - C.y)*(x - C.x) + (C.x - B.x)*(y - C.y)) / denom;
    float w2 = ((C.y - A.y)*(x - C.x) + (A.x - C.x)*(y - C.y)) / denom;
    float w3 = 1 - w1 - w2;

    return w1*A.z + w2*B.z + w3*C.z;
}
```

## cameraControl

使用鍵盤控制相機移動

- W / S：前後
- A / D：左右
- Q / E：上下

## Back-face Culling (GameObject::debugDraw)

利用三角形在 NDC (-1~1) 中的投影結果

- 透過計算 2D 三角形的有向面積
- 若面積符號表示「背面」，則跳過不畫

使用的程式碼

```
float area = (B.x - A.x) * (C.y - A.y) -
             (C.x - A.x) * (B.y - A.y);

if (area <= 0) continue; // 背面 → 不畫
```
