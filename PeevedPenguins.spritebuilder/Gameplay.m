//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Otavio Monteagudo on 4/10/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Gameplay.h"

@implementation Gameplay
{
    CCPhysicsNode *_physicsNode;
    
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    
    CCPhysicsNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    
    
}


// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
    // highlights physics bodies & joints, making debug process easier.
    _physicsNode.debugDraw = TRUE;
    
    // this will load the first level and add it as a child of _levelNode (pre defined in SpriteBuilder), which will load the logic and render the appearence of the first level in the level area of the Gameplay scene.
    CCScene *level = [CCBReader loadAsScene:@"Levels/Level1"];
    [_levelNode addChild:level];
    
    // nothing shall collide with our invisible nodes
    // a collisionMask attribute sets which objects affected by the PhysicsNode will collide with the specific object. Below the collision mask does not contain any objects (since the node is invisible and is used mainly to hack the catapult arm into behaving in a more real way)
    _pullbackNode.physicsBody.collisionMask = @[];
    _mouseJointNode.physicsBody.collisionMask = @[];
    
    
}

// called on every touch event in the gameplay scene
- (void)touchBegan:(CCTouch *)touch withEvent:(CCTouchEvent *)event {
    //[self launchPenguin]; // triggers the code below when screen is touched.
    
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    // start catapult dragging when a touch inside of the catapult arm occurs
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        // move the mouseJointNode to the touch position
        _mouseJointNode.position = touchLocation;
        
        // setup a spring joint between the mouseJointNode and the catapultArm
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
    }
}

// drags the catapult
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    // whenever touches move, update the position of the mouseJointNode to the touch position
    CGPoint touchLocation = [touch locationInNode: _contentNode];
    _mouseJointNode.position = touchLocation;
}

// triggered when catapult is released after touch
- (void)releaseCatapult {
    if (_mouseJoint != nil)
    {
        // releases the joint and lets the catapult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
    }
}


-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // when touches end, meaning the user releases their finger, release the catapult
    [self releaseCatapult];
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    // when touches are cancelled, meaning the user drags their finger off the screen or onto something else, release the catapult
    [self releaseCatapult];
}


- (void)launchPenguin {
    // loads the Penguin.ccb we have set up in Spritebuilder
    CCNode* penguin = [CCBReader load:@"Penguin"];
    // position the penguin at the bowl of the catapult
    penguin.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    
    // add the penguin to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:penguin];
    
    // manually create & apply a force to launch the penguin
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
    
    // ensure followed object is in visible area when starting; focuses on followed object so the screen moves along with the specific object.
    /*self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox]; // worldBoundary defines a maximum space of the screen so the screen movement won't cross the scene bounds.
    [self runAction:follow];*/
    
    // see code above for detailed explanations. This code here below uses the contentNode instead of the whole gameplay scene as a reference to move away from. Still uses the Gameplay scene boundaries as a reference for maximum positions, since the button is inside the contentNode, it won't follow the penguin as well.
    self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];
}

- (void)retry {
    // reload the level
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

@end
