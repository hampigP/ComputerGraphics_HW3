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
