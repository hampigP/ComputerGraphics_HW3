public class Camera {
    Matrix4 projection = new Matrix4();
    Matrix4 worldView = new Matrix4();
    int wid;
    int hei;
    float near;
    float far;
    Transform transform;

    Camera() {
        wid = 256;
        hei = 256;
        worldView.makeIdentity();
        projection.makeIdentity();
        transform = new Transform();
    }

    Matrix4 inverseProjection() {
        Matrix4 invProjection = Matrix4.Zero();
        float a = projection.m[0];
        float b = projection.m[5];
        float c = projection.m[10];
        float d = projection.m[11];
        float e = projection.m[14];
        invProjection.m[0] = 1.0f / a;
        invProjection.m[5] = 1.0f / b;
        invProjection.m[11] = 1.0f / e;
        invProjection.m[14] = 1.0f / d;
        invProjection.m[15] = -c / (d * e);
        return invProjection;
    }

    Matrix4 Matrix() {
        return projection.mult(worldView);
    }

    void setSize(int w, int h, float n, float f) {
        wid = w;
        hei = h;
        near = n;
        far = f;
        
        // TODO HW3
        // This function takes four parameters, which are 
        // the width of the screen, the height of the screen
        // the near plane and the far plane of the camera.
        // Where GH_FOV has been declared as a global variable.
        // Finally, pass the result into projection matrix.
        // 透視投影矩陣 (類似 OpenGL 的 Perspective)
        float aspect = (float) w / (float) h;
        float fovRad = radians(GH_FOV);
        float f_y = 1.0f / tan(fovRad * 0.5f);  // 1 / tan(FOV/2)
        Matrix4 p = Matrix4.Zero();
        // | f_y/aspect   0          0               0 |
        // |     0      f_y          0               0 |
        // |     0        0   (f+n)/(n-f)   (2fn)/(n-f)|
        // |     0        0         -1               0 |
        p.m[0]  = f_y / aspect;
        p.m[5]  = f_y;

        p.m[10] = (f + n) / (n - f);
        p.m[11] = (2.0f * f * n) / (n - f);

        p.m[14] = -1.0f;
        p.m[15] = 0.0f;

        projection = p;
        //projection = Matrix4.Identity();

    }

    void setPositionOrientation(Vector3 pos, float rotX, float rotY) {

    }

    void setPositionOrientation(Vector3 pos, Vector3 lookat) {
        // TODO HW3
        // This function takes two parameters, which are the position of the camera and
        // the point the camera is looking at.
        // We uses topVector = (0,1,0) to calculate the eye matrix.
        // Finally, pass the result into worldView matrix.

        //worldView = Matrix4.Identity();
        // 以 OpenGL 的 lookAt 為參考：
        // f = normalize(lookat - pos)      (camera forward)
        // s = normalize(cross(f, up))      (camera right)
        // u = cross(s, f)                  (camera up)
        // View = [  s.x  s.y  s.z  -dot(s,pos)
        //           u.x  u.y  u.z  -dot(u,pos)
        //          -f.x -f.y -f.z   dot(f,pos)
        //           0    0    0        1     ]

        Vector3 up = new Vector3(0, 1, 0);

        // forward 方向（從相機指向 lookat）
        Vector3 f = Vector3.sub(lookat, pos);
        if (f.norm() == 0) {
            // 避免 pos == lookat 時除以 0，隨便給一個方向
            f = new Vector3(0, 0, -1);
        }
        f.normalize();

        // right = f × up
        Vector3 s = Vector3.cross(f, up);
        if (s.norm() == 0) {
            // 如果 up 跟 f 幾乎共線，就改用另一個 up
            up = new Vector3(0, 0, 1);
            s = Vector3.cross(f, up);
        }
        s.normalize();

        // 真正的 up = s × f
        Vector3 u = Vector3.cross(s, f);

        Matrix4 view = Matrix4.Identity();

        // 旋轉部分（前三個 column）
        view.m[0] = s.x;  view.m[1] = s.y;  view.m[2]  = s.z;
        view.m[4] = u.x;  view.m[5] = u.y;  view.m[6]  = u.z;
        view.m[8] = -f.x; view.m[9] = -f.y; view.m[10] = -f.z;

        // 平移部分（最後一欄）
        view.m[3]  = -Vector3.dot(s, pos);
        view.m[7]  = -Vector3.dot(u, pos);
        view.m[11] =  Vector3.dot(f, pos);

        view.m[12] = 0.0f;
        view.m[13] = 0.0f;
        view.m[14] = 0.0f;
        view.m[15] = 1.0f;

        worldView = view;
    }
}
