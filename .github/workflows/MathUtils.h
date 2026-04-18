//
//  MathUtils.h
//  WXR
//
//  Math utilities for ESP rendering
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

// Vector structures
typedef struct {
    float x, y, z;
} Vector3;

typedef struct {
    float x, y, z, w;
} Vector4;

// World to screen conversion
float WorldToScreen(const float viewMatrix[16], float worldX, float worldY, float worldZ, 
                   double screenWidth, double screenHeight, float *outX, float *outY);

// Matrix operations
void MatrixMultiply(const float *a, const float *b, float *result);
void MatrixInverse(const float *matrix, float *result);

// Vector operations
Vector3 Vector3Add(Vector3 a, Vector3 b);
Vector3 Vector3Subtract(Vector3 a, Vector3 b);
Vector3 Vector3Multiply(Vector3 v, float scalar);
float Vector3Length(Vector3 v);
float Vector3Distance(Vector3 a, Vector3 b);
Vector3 Vector3Normalize(Vector3 v);
float Vector3Dot(Vector3 a, Vector3 b);

// Angle calculations
float CalculateAngle(Vector3 from, Vector3 to);
Vector3 CalculateAngles(Vector3 from, Vector3 to);

// Utility functions
BOOL IsOnScreen(float x, float y, double width, double height);
CGPoint ClampToScreen(CGPoint point, double width, double height, float margin);
