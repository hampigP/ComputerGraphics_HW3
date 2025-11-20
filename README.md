# ComputerGraphics_HW3
[DEMO Video](https://youtu.be/fWdH75_qadg)

## Model Matrix (GameObject::localToWorld)

- 平移 (Transition)：根據物件的 `transform.position` 建立平移矩陣。
- 旋轉 (Rotation X/Y/Z)：先繞 Z 軸，再 X 軸，再 Y 軸，依序建立對對應旋轉矩陣
- 縮放 (Scale)：根據物件的 `transform.scale` 建立縮放矩陣
- 乘法順序：採用 `T * R_y * R_x * R_z * S` 的順序，以確保模型先縮放、再旋轉、最後平移

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

這樣可以確保模型以自身原點為基礎進行縮放、旋轉，再移動到世界空間

## View Matrix (Camera::setPositionOrientation)

在 `Camera::setPositionOrientatio(Vector3 pos, Vector3 lookat)` 中，實作類似 OpenGL 的 LookAt 流程：

- forward = normalize (lookat - position)：攝影機「前方」方向
- right = normalize (forward X up)：攝影機「右方」方向。`up` 預設為 (0,1,0)
- up = right X forward：攝影機新的「上方」方向
- 組合矩陣：前三欄 s,u,-f，最後一欄為 dot(s,-pos), dot(u, -pos), dot(f, pos) 等平移部分

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

這段程式碼讓物件從世界座標轉換到攝影機座標，使「攝影機固定 / 物件移動」的邏輯更加清晰

## Projection Matrix (Camera::setSize)

在 `Camera::setSize(int w, int h, float n, float f)`中，利用螢幕寬高比與近 / 遠平面建構透視投影矩陣

- 計算 `aspect = w/h`
- 計算 `fy = 1 / tan(FOV / 2)`
- 將矩陣填入如下形式：

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

這樣可以將 3D 座標從攝影機座標投影至剪裁空間，實現遠近縮放 (Perspective) 效果

## 深度計算 (util::getDepth)

為了實現遮擋 (Z-buffer) 或判斷進遠順序，在 `util::getDepth()` 中實作了三角形重心插值：

1. 將螢幕上某點 (x,y) 對應到三角形頂點 A, B, C
2. 計算重心座標 w1, w2, w3
3. 利用插值取得 z 值：

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

這樣在繪製線或三角形頂點的時候，可以比較哪個深度值較小 (較近) 已決定是否覆蓋

## cameraControl

在 `HW3::cameraControl()` 函式裡實作鍵盤交互：

- W / S：沿 Z 軸前後移動
- A / D：沿 X 軸左右移動
- Q / E：沿 Y 軸上下移動

例如：

```
if (keyPressed) {
    if (key == 'w' || key == 'W') cam_position.z += speed;
    else if (key == 's' || key == 'S') cam_position.z -= speed;
    else if (key == 'a' || key == 'A') cam_position.x -= speed;
    else if (key == 'd' || key == 'D') cam_position.x += speed;
    else if (key == 'q' || key == 'Q') cam_position.y += speed;
    else if (key == 'e' || key == 'E') cam_position.y -= speed;
}
main_camera.setPositionOrientation(cam_position, lookat);
```

這樣使用者即可透過鍵盤控制視點，以不同角度觀看 3D 模型

## Back-face Culling (GameObject::debugDraw)

在 `GameObject::debugDraw()` 中，加入如下判斷：

1. 將三角形頂點變換至 NDC space
2. 計算在 NDC x-y 平面上的「有向面積」
```
float area = (B.x - A.x)*(C.y - A.y) - (C.x - A.x)*(B.y - A.y);
if (area <= 0) continue;
```

3. 若面積小於等於 0 ，代表三角形背向攝影機，則跳過不畫。這樣能省去繪製「背對鏡頭」的邊線，提高效率並減少雜訊
