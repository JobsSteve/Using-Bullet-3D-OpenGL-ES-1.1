//
//  BouncingBallViewController.m
//  BouncingBall
//
//  Created by Taylor Triggs on 5/17/12.
//  Copyright (c) 2012 Cal State Channel Islands. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "BouncingBallViewController.h"
#import "EAGLView.h"
#import "sphere.h"
#import "cube.h"

@interface BouncingBallViewController ()
{
    btDefaultCollisionConfiguration *collisionConfiguration;
    btCollisionDispatcher *dispatcher;
    btSequentialImpulseConstraintSolver *solver;
    //btDiscreteDynamicsWorld *dynamicsWorld;
    btAlignedObjectArray<btCollisionShape*> collisionShapes;
}

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) CADisplayLink *displayLink;

// Init OpenGL ES ready to render in 3D
- (void)initOpenGLES1;

// Init the game objects and ivars
- (void)initGame;

// Update the scene
- (void)updateWithDelta:(float)aDelta;

// Render the scene
- (void)drawFrame;

// Render the models
-(void)lines;
-(void)cube;
-(void)sphere;

// Manages the game loop and as called by the displaylink
- (void)gameLoop;

@end

@implementation BouncingBallViewController

@synthesize animating, context, displayLink;

- (void)awakeFromNib
{
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    
    if (!aContext)
        NSLog(@"Failed to create ES context");
    else if (![EAGLContext setCurrentContext:aContext])
        NSLog(@"Failed to set ES context current");
    
	self.context = aContext;
	[aContext release];
	
    [(EAGLView *)self.view setContext:context];
    [(EAGLView *)self.view setFramebuffer];
    
    animating = FALSE;
    animationFrameInterval = 1;
    self.displayLink = nil;
    
    // Init game
    [self initGame];
}

- (void)dealloc
{
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
    
    [context release];
    
	delete dynamicsWorld;
    
	delete solver;
    
    delete fallRigidBody;
    
	delete dispatcher;
    
	delete collisionConfiguration;

    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated
{
    // Init OpenGL ES 1
    [self initOpenGLES1];
    
    [self startAnimation];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
    
    // Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1) {
        animationFrameInterval = frameInterval;
        
        if (animating) {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating) {
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(gameLoop)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        self.displayLink = aDisplayLink;
        
        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating) {
        [self.displayLink invalidate];
        self.displayLink = nil;
        animating = FALSE;
    }
}

- (void)initGame
{
    // Generate the floors vertices
    GLfloat z = -20.0f;
    for (uint index = 0; index < 81; index += 2) 
    {
        zFloorVertices[index].x = -20.0;
        zFloorVertices[index].y = -1;
        zFloorVertices[index].z = z;
        
        zFloorVertices[index+1].x = 20.0;
        zFloorVertices[index+1].y = -1;
        zFloorVertices[index+1].z = z;
        
        z += 2.0f;
    }
    
    GLfloat x = -20.0f;
    for (uint index = 0; index < 81; index += 2) 
    {
        xFloorVertices[index].x = x;
        xFloorVertices[index].y = -1;
        xFloorVertices[index].z = -20.0f;
        
        xFloorVertices[index+1].x = x;
        xFloorVertices[index+1].y = -1;
        xFloorVertices[index+1].z = 20;
        
        x += 2.0f;
    }
    
    btBroadphaseInterface* broadphase = new btDbvtBroadphase();
	btDefaultCollisionConfiguration* collisionConfiguration = new btDefaultCollisionConfiguration();
	btCollisionDispatcher* dispatcher = new btCollisionDispatcher(collisionConfiguration);
	btSequentialImpulseConstraintSolver* solver = new btSequentialImpulseConstraintSolver();
	dynamicsWorld = new btDiscreteDynamicsWorld(dispatcher, broadphase, solver, collisionConfiguration);
	dynamicsWorld->setGravity(btVector3(0, -9.8, 0));
    
    // Creates boxes on +X
    for (int i = 0; i < 4; i++) 
    {
        btCollisionShape *groundShape = new btBoxShape(btVector3(1, 0.1, 1));
        btDefaultMotionState *groundMotionState = new btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1),btVector3(0 +i+i+i+i+i, 0, 0)));


        btRigidBody::btRigidBodyConstructionInfo groundRigidBodyCI(0,groundMotionState,groundShape,btVector3(0, 0, 0));
        groundRigidBodyCI.m_restitution = 0.0;
        btRigidBody* groundRigidBody = new btRigidBody(groundRigidBodyCI);
        dynamicsWorld->addRigidBody(groundRigidBody);
    }
    
    // Creates boxes on -Z
    for (int i = 0; i < 4; i++) 
    {
        btCollisionShape *groundShape = new btBoxShape(btVector3(1, 0.1, 1));
        btDefaultMotionState *groundMotionState = new btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1),btVector3(0, 0, -i-i-i-i-i)));
        
        
        btRigidBody::btRigidBodyConstructionInfo groundRigidBodyCI(0,groundMotionState,groundShape,btVector3(0, 0, 0));
        groundRigidBodyCI.m_restitution = 0.0;
        btRigidBody* groundRigidBody = new btRigidBody(groundRigidBodyCI);
        dynamicsWorld->addRigidBody(groundRigidBody);
    }
    
    // Creates boxes on +Z, toward camera init
    for (int i = 0; i < 4; i++) 
    {
        btCollisionShape *groundShape = new btBoxShape(btVector3(1, 0.1, 1));
        btDefaultMotionState *groundMotionState = new btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1),btVector3(0, 0, +i+i+i+i+i)));
        
        
        btRigidBody::btRigidBodyConstructionInfo groundRigidBodyCI(0,groundMotionState,groundShape,btVector3(0, 0, 0));
        groundRigidBodyCI.m_restitution = 0.0;
        btRigidBody* groundRigidBody = new btRigidBody(groundRigidBodyCI);
        dynamicsWorld->addRigidBody(groundRigidBody);
    }
    
    // Creates boxes on diagonals...
    for (int i = 0; i < 4; i++) 
    {
        btCollisionShape *groundShape = new btBoxShape(btVector3(1, 0.1, 1));
        btDefaultMotionState *groundMotionState = new btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1),btVector3(0+i+i+i+i+i, 0, 0+i+i+i+i+i)));
        
        
        btRigidBody::btRigidBodyConstructionInfo groundRigidBodyCI(0,groundMotionState,groundShape,btVector3(0, 0, 0));
        groundRigidBodyCI.m_restitution = 0.0;
        btRigidBody* groundRigidBody = new btRigidBody(groundRigidBodyCI);
        dynamicsWorld->addRigidBody(groundRigidBody);
    }
    
    // Creates boxes on diagonals...
    for (int i = 0; i < 4; i++) 
    {
        btCollisionShape *groundShape = new btBoxShape(btVector3(1, 0.1, 1));
        btDefaultMotionState *groundMotionState = new btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1),btVector3(0+i+i+i+i+i, 0+i+i+i+i+i, 0+i+i+i+i+i)));
        
        
        btRigidBody::btRigidBodyConstructionInfo groundRigidBodyCI(0,groundMotionState,groundShape,btVector3(0, 0, 0));
        groundRigidBodyCI.m_restitution = 0.0;
        btRigidBody* groundRigidBody = new btRigidBody(groundRigidBodyCI);
        dynamicsWorld->addRigidBody(groundRigidBody);
    }

	
    // Sphere Motion
    btCollisionShape *fallShape = new btSphereShape(1);
	btDefaultMotionState *fallMotionState = new btDefaultMotionState(btTransform(btQuaternion(0, 0, 0, 1), btVector3(0, 6.5, 0)));
	btScalar mass = 1;
	btVector3 fallInertia(0, 0, 0);
	fallShape->calculateLocalInertia(mass, fallInertia);
    btRigidBody::btRigidBodyConstructionInfo fallRigidBodyCI(mass,fallMotionState,fallShape,fallInertia);
	fallRigidBodyCI.m_restitution = 0.3;
	fallRigidBody = new btRigidBody(fallRigidBodyCI);
	fallRigidBody->setDamping(0.3, 1);
    fallRigidBody->setLinearFactor(btVector3(1, 1, 1));      // allows ball to jump in x y and z directions
    fallRigidBody->setAngularFactor(btVector3(0, 0, 1));
	dynamicsWorld->addRigidBody(fallRigidBody);
}

#pragma mark -
#pragma mark Game Loop

#define MAXIMUM_FRAME_RATE 90.0f
#define MINIMUM_FRAME_RATE 30.0f
#define UPDATE_INTERVAL (1.0 / MAXIMUM_FRAME_RATE)
#define MAX_CYCLES_PER_FRAME (MAXIMUM_FRAME_RATE / MINIMUM_FRAME_RATE)

- (void)gameLoop 
{
	static double lastFrameTime = 0.0f;
	static double cyclesLeftOver = 0.0f;
	double currentTime;
	double updateIterations;
	
	// Apple advises to use CACurrentMediaTime() as CFAbsoluteTimeGetCurrent() is synced with the mobile
	// network time and so could change causing hiccups.
	currentTime = CACurrentMediaTime();
	updateIterations = ((currentTime - lastFrameTime) + cyclesLeftOver);
	
	if(updateIterations > (MAX_CYCLES_PER_FRAME * UPDATE_INTERVAL))
		updateIterations = (MAX_CYCLES_PER_FRAME * UPDATE_INTERVAL);
	
	while (updateIterations >= UPDATE_INTERVAL) 
    {
		updateIterations -= UPDATE_INTERVAL;
		
		// Update the game logic passing in the fixed update interval as the delta
		[self updateWithDelta:UPDATE_INTERVAL];		
	}
	
	cyclesLeftOver = updateIterations;
	lastFrameTime = currentTime;
    
    [self drawFrame];
}

#pragma mark -
#pragma mark Update

- (void)updateWithDelta:(float)aDelta
{
    angle += 0.2f;
    
    dynamicsWorld->stepSimulation(1/60.f,10);
    
    btTransform trans;
    fallRigidBody->getMotionState()->getWorldTransform(trans);
    
    btVector3 fallRBPos = trans.getOrigin();
    
    if (fallRigidBody->getLinearVelocity().length() > -0.1 && fallRigidBody->getLinearVelocity().length() < 0.1 )
    {
        // +X
        //fallRigidBody->applyImpulse(btVector3(4,8,0), btVector3(fallRBPos.getX(), fallRBPos.getY(), fallRBPos.getZ()));
        //fallRigidBody->activate(true);
        fallRigidBody->applyCentralImpulse(btVector3(4,12,4));
    }
    
    spherePosition = btVector3(trans.getOrigin().getX(), trans.getOrigin().getY(), trans.getOrigin().getZ());
    btQuaternion qRotation1 = trans.getRotation();
    sphereAngle = qRotation1.getAngle();
    
    if (trans.getOrigin().getY() < -1 )
        NSLog(@"Game Over");
    
    //NSLog(@"sphere height: %.2f \n", trans.getOrigin().getY()); 
    //NSLog(@"Sphere = (%f, %f)    rotation = %f", spherePosition.getX(), spherePosition.getY(), sphereAngle);
}

- (void)drawFrame
{
    [(EAGLView *)self.view setFramebuffer];
        
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // Position the camera back from the origin and slightly raised
    gluLookAt(spherePosition.getX(), 5, spherePosition.getZ() + 30, spherePosition.getX(), spherePosition.getY(), spherePosition.getZ(), 0, 1, 0);
    
    // Rotate the scene
    //glRotatef(angle, 0, 1, 0);
    
    // Draw Grid
    [self lines];
    
    // Draw Boxes
    [self createWorld];
    
    // Bullet physics needs to activate objects to keep them alive... 
    // If they aren't moving for a while, it turns them off to save processing time
    // in this example we use the sphere all the time...
    ((btCollisionObject *)fallRigidBody)->activate();
    
    // Draw Sphere
    glPushMatrix();
        glTranslatef(spherePosition.getX(), spherePosition.getY(), spherePosition.getZ());
        glRotatef(sphereAngle * 180.0 / 3.14159, 0.0, 0.0, 1.0);
        [self sphere];
    glPopMatrix();
    
    [(EAGLView *)self.view presentFramebuffer];
}

-(void)createWorld
{
    // Generates +X openGL cube positions
    for (int i = 0; i < 4; i++) 
    {
        glPushMatrix();
            glTranslatef(0 +i+i+i+i+i, 0, 0);
            [self cube];
        glPopMatrix();
    }
    
    // Generates Z openGL cube positions
    for (int i = 0; i < 4; i++) 
    {
        glPushMatrix();
            glTranslatef(0, 0, 0 +i+i+i+i+i);
            [self cube];
        glPopMatrix();
    }
    
    // Generates Z openGL cube positions
    for (int i = 0; i < 4; i++) 
    {
        glPushMatrix();
            glTranslatef(0, 0, 0 -i-i-i-i-i);
            [self cube];
        glPopMatrix();
    }
    
    // Generates diagonals...
    for (int i = 0; i < 4; i++) 
    {
        glPushMatrix();
            glTranslatef(0 +i+i+i+i+i, 0, 0 +i+i+i+i+i);
            [self cube];
        glPopMatrix();
    }
    
    // Generates diagonals in air...
    for (int i = 0; i < 4; i++) 
    {
        glPushMatrix();
            glTranslatef(0 +i+i+i+i+i, 0 +i+i+i+i+i, 0 +i+i+i+i+i);
            [self cube];
        glPopMatrix();
    }
}

-(void)lines
{
    // LINES
    // Set the color to be used when drawing the lines
    //glColor4f(1.0f, 1.0f, 1.0f, 1.0f);
    GLfloat ambientAndDiffuse1[] = {1.0, 1.0, 1.0, 1.0};
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, ambientAndDiffuse1);
    
    // Disable the color array as we want the grid to be all white
    glDisableClientState(GL_COLOR_ARRAY);
    
    // Enable the Vertex Array so that the vervices held in the vertex
    // arrays that have been set up can be used to render the grid lines.
    glEnableClientState(GL_VERTEX_ARRAY);
    
    // Point to the array defining the horizontal line vertices and render them
    glVertexPointer(3, GL_FLOAT, 0, zFloorVertices);
    glDrawArrays(GL_LINES, 0, 42);
    
    // Point to the array defining the vertical line vertices and render those as well
    glVertexPointer(3, GL_FLOAT, 0, xFloorVertices);
    glDrawArrays(GL_LINES, 0, 42);
}

-(void)cube
{
    // CUBE 
    GLfloat ambientAndDiffuseCube[] = {0.0, 1.0, 0.0, 1.0};
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, ambientAndDiffuseCube);
    
    glEnableClientState(GL_NORMAL_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, 0, cubeVerts);
    glNormalPointer(GL_FLOAT, 0, cubeNormals);
    
    glPushMatrix();
    glTranslatef(0, -0.4, 0);
    glDrawArrays(GL_TRIANGLES, 0, cubeNumVerts);
    glPopMatrix();
}

-(void)sphere
{
    // SPHERE
    GLfloat ambientAndDiffuse[] = {1.0, 0.0, 0.0, 1.0};
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, ambientAndDiffuse);
    
    glEnableClientState(GL_NORMAL_ARRAY);
    
    glVertexPointer(3, GL_FLOAT, 0, sphereVerts);
    glNormalPointer(GL_FLOAT, 0, sphereNormals);
    glTexCoordPointer(2, GL_FLOAT, 0, sphereTexCoords);
    
    //glTranslatef(0.0f, 1.5f, 0.0f);
    
/*#if TARGET_IPHONE_SIMULATOR
    static GLfloat spinX = 0.0, spinY = 0.0;
    glRotatef(spinX, 0.0, 0.0, 0.5);
    glRotatef(spinY, 0.0, 0.5, 0.0);
    glRotatef(45.0, 0.5, 0.0, 0.0);
    spinX += 0.5;
    spinY += 0.15;   
#endif */
    
    glPushMatrix();
    //glTranslatef(0, 2, 0);
    glDrawArrays(GL_TRIANGLES, 0, sphereNumVerts);
    glPopMatrix();
}

- (void)initOpenGLES1
{
    glShadeModel(GL_SMOOTH);
    
    // Enable lighting
    glEnable(GL_LIGHTING);
    
    // Turn the first light on
    glEnable(GL_LIGHT0);
    
    const GLfloat			lightAmbient[] =  {0.2, 0.2, 0.2, 1.0};
	const GLfloat			lightDiffuse[] =  {0.8, 0.8, 0.8, 1.0}; // changes color
	const GLfloat			matAmbient[] =    {0.3, 0.3, 0.3, 0.5};
	const GLfloat			matDiffuse[] =    {1.0, 1.0, 1.0, 1.0};	
	const GLfloat			matSpecular[] =   {1.0, 1.0, 1.0, 1.0};
	const GLfloat			lightPosition[] = {0.0, 0.0, 1.0, 0.0}; 
	const GLfloat			lightShininess =   100.0;
	
	//Configure OpenGL lighting
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	
    glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, matAmbient);
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, matDiffuse);
	glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, matSpecular);
	glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, lightShininess);
	
    glLightfv(GL_LIGHT0, GL_AMBIENT, lightAmbient);
	glLightfv(GL_LIGHT0, GL_DIFFUSE, lightDiffuse);
	glLightfv(GL_LIGHT0, GL_POSITION, lightPosition); 
    
    // Define a cutoff angle. This defines a 90° field of vision, since the cutoff
    // is number of degrees to each side of an imaginary line drawn from the light's
    // position along the vector supplied in GL_SPOT_DIRECTION above
    glLightf(GL_LIGHT0, GL_SPOT_CUTOFF, 40.0);
    
    // Set the clear color
    glClearColor(0, 0, 0, 1.0f);
    
    // Projection Matrix config
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    CGSize layerSize = self.view.layer.frame.size;
    gluPerspective(45.0f, (GLfloat)layerSize.height / (GLfloat)layerSize.width, 0.1f, 750.0f);
    
    // Modelview Matrix config
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    // This next line is not really needed as it is the default for OpenGL ES
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_BLEND);
    
    // Enable depth testing
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
    glDepthMask(GL_TRUE);
}

@end