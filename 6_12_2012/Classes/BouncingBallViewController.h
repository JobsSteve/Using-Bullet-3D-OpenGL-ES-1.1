//
//  BouncingBallViewController.h
//  BouncingBall
//
//  Created by Taylor Triggs on 5/17/12.
//  Copyright (c) 2012 Cal State Channel Islands. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "CommonOpenGL.h"
#import "btBulletDynamicsCommon.h"
#import "btBulletCollisionCommon.h"

@interface BouncingBallViewController : UIViewController {
@private
    EAGLContext *context;
    GLuint program;
    
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *displayLink;
    
    // Angle of rotation
    GLfloat angle;
    
    // Floor Vertices
    SSVertex3D zFloorVertices[81];
    SSVertex3D xFloorVertices[81];
        
    btDiscreteDynamicsWorld *dynamicsWorld;
	btRigidBody *fallRigidBody;
    
    btVector3 spherePosition;
    btScalar sphereAngle;  
    
    btVector3 cubePosition;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void)startAnimation;
- (void)stopAnimation;

@end
