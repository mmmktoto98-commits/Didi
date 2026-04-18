//
//  MathUtils.m
//  WXR
//
//  Math utilities implementation
//

#import "MathUtils.h"
#import <math.h>

float WorldToScreen(const float viewMatrix[16], float worldX, float worldY, float worldZ,
                   double screenWidth, double screenHeight, float *outX, float *outY) {
    // Transform world coordinates to clip space
    float clipX = viewMatrix[0] * worldX + viewMatrix[1] * worldY + viewMatrix[2] * worldZ + viewMatrix[3];
    float clipY = viewMatrix[4] * worldX + viewMatrix[5] * worldY + viewMatrix[6] * worldZ + viewMatrix[7];
    float clipZ = viewMatrix[8] * worldX + viewMatrix[9] * worldY + viewMatrix[10] * worldZ + viewMatrix[11];
    float clipW = viewMatrix[12] * worldX + viewMatrix[13] * worldY + viewMatrix[14] * worldZ + viewMatrix[15];
    
    if (clipW < 0.01f) {
        return 0.0f; // Behind camera
    }
    
    // Perspective divide
    float ndcX = clipX / clipW;
    float ndcY = clipY / clipW;
    
    // Convert to screen space
    *outX = (ndcX + 1.0f) * 0.5f * screenWidth;
    *outY = (1.0f - ndcY) * 0.5f * screenHeight;
    
    return clipW;
}

void MatrixMultiply(const float *a, const float *b, float *result) {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < 4; j++) {
            result[i * 4 + j] = 0;
            for (int k = 0; k < 4; k++) {
                result[i * 4 + j] += a[i * 4 + k] * b[k * 4 + j];
            }
        }
    }
}

Vector3 Vector3Add(Vector3 a, Vector3 b) {
    return (Vector3){a.x + b.x, a.y + b.y, a.z + b.z};
}

Vector3 Vector3Subtract(Vector3 a, Vector3 b) {
    return (Vector3){a.x - b.x, a.y - b.y, a.z - b.z};
}

Vector3 Vector3Multiply(Vector3 v, float scalar) {
    return (Vector3){v.x * scalar, v.y * scalar, v.z * scalar};
}

float Vector3Length(Vector3 v) {
    return sqrtf(v.x * v.x + v.y * v.y + v.z * v.z);
}

float Vector3Distance(Vector3 a, Vector3 b) {
    return Vector3Length(Vector3Subtract(a, b));
}

Vector3 Vector3Normalize(Vector3 v) {
    float length = Vector3Length(v);
    if (length < 0.0001f) return (Vector3){0, 0, 0};
    return Vector3Multiply(v, 1.0f / length);
}

float Vector3Dot(Vector3 a, Vector3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

float CalculateAngle(Vector3 from, Vector3 to) {
    Vector3 delta = Vector3Subtract(to, from);
    float distance = Vector3Length(delta);
    if (distance < 0.0001f) return 0.0f;
    
    float pitch = asinf(delta.z / distance) * (180.0f / M_PI);
    float yaw = atan2f(delta.y, delta.x) * (180.0f / M_PI);
    
    return sqrtf(pitch * pitch + yaw * yaw);
}

Vector3 CalculateAngles(Vector3 from, Vector3 to) {
    Vector3 delta = Vector3Subtract(to, from);
    float distance = sqrtf(delta.x * delta.x + delta.y * delta.y);
    
    float pitch = atan2f(-delta.z, distance) * (180.0f / M_PI);
    float yaw = atan2f(delta.y, delta.x) * (180.0f / M_PI);
    
    return (Vector3){pitch, yaw, 0};
}

BOOL IsOnScreen(float x, float y, double width, double height) {
    return x >= 0 && x <= width && y >= 0 && y <= height;
}

CGPoint ClampToScreen(CGPoint point, double width, double height, float margin) {
    float x = fmaxf(margin, fminf(width - margin, point.x));
    float y = fmaxf(margin, fminf(height - margin, point.y));
    return CGPointMake(x, y);
}
