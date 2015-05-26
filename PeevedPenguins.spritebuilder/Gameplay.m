//
//  Gameplay.m
//  PeevedPenguins
//
//  Created by Otavio Monteagudo on 4/10/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "Penguin.h"

@implementation Gameplay
{
    CCPhysicsNode *_physicsNode;
    
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    
    CCPhysicsNode *_pullbackNode;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    
    Penguin *_currentPenguin;
    CCPhysicsJoint *_penguinCatapultJoint;
    
    CCAction *_followPenguin;
    
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
    
    // delegates collision handling to the CCPhysicsCollisionDelegate object pre-defined in SpriteBuilder (see Gameplay.h).
    _physicsNode.collisionDelegate = self;
    
    
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
        
        // setup a spring joint between the mouseJointNode and the catapultArm; other end of the joint is set dynamically according to the touch location.
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
        
        // create a penguin from the ccb-file; CCBReader returns only CCNodes, Penguin inherits from it but Penguin class must be casted.
        _currentPenguin = (Penguin*)[CCBReader load:@"Penguin"];
        // initially position it on the scoop. 34,138 is the position in the node space of the _catapultArm
        CGPoint penguinPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        // transform the world position to the node space to which the penguin will be added (_physicsNode)
        _currentPenguin.position = [_physicsNode convertToNodeSpace:penguinPosition];
        // add it to the physics world
        [_physicsNode addChild:_currentPenguin];
        // we don't want the penguin to rotate in the scoop
        _currentPenguin.physicsBody.allowsRotation = FALSE;
        
        // create a joint to keep the penguin fixed to the scoop until the catapult is released
        _penguinCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_currentPenguin.physicsBody bodyB:_catapultArm.physicsBody anchorA:_currentPenguin.anchorPointInPoints];
    }
}

// drags the catapult
- (void)touchMoved:(CCTouch *)touch withEvent:(UIEvent *)event
{
    // whenever touches move, update the position of the mouseJointNode to the touch position
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

// triggered when catapult is released after touch
- (void)releaseCatapult {
    if (_mouseJoint != nil)
    {
        // releases the joint and lets the catapult snap back
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        // releases the joint and lets the penguin fly
        [_penguinCatapultJoint invalidate];
        _penguinCatapultJoint = nil;
        
        // after snapping rotation is fine
        _currentPenguin.physicsBody.allowsRotation = TRUE;
        
        // follow the flying penguin
        /*CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:follow];*/
        _followPenguin = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
        [_contentNode runAction:_followPenguin];
        // signalizes that the currently loaded penguin has been launched.
        _currentPenguin.launched = TRUE;
        
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
    //_currentPenguin = [CCBReader load:@"Penguin"];
    
    // position the penguin at the bowl of the catapult
    penguin.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    //_currentPenguin.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    
    // add the penguin to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:penguin];
    //[_physicsNode addChild:_currentPenguin];
    
    // manually create & apply a force to launch the penguin
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [penguin.physicsBody applyForce:force];
    
    /*CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [_currentPenguin.physicsBody applyForce:force];*/
    
    // ensure followed object is in visible area when starting; focuses on followed object so the screen moves along with the specific object.
    self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox]; // worldBoundary defines a maximum space of the screen so the screen movement won't cross the scene bounds.
    [self runAction:follow];
    
    // see code above for detailed explanations. This code here below uses the contentNode instead of the whole gameplay scene as a reference to move away from. Still uses the Gameplay scene boundaries as a reference for maximum positions, since the button is inside the contentNode, it won't follow the penguin as well.
    /*self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:penguin worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];*/
    /*self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:_currentPenguin worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];*/
}

// delegate method from Chipmunk (Cocos2D's physics engine) when a seal object collides into any other object that's a physics node.

-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair seal:(CCNode *)nodeA wildcard:(CCNode *)nodeB
{
    //CCLOG(@"Something collided with a seal!");
    
    // gets kitectic energy of collision between seal and something else;
    float energy = [pair totalKineticEnergy];
    
    // if energy is large enough, remove the seal
    if (energy > 5000.f) {
        [[_physicsNode space] addPostStepBlock:^{ // 'addPostStepBlock' ensures the sealRemoved is only run once in case more than one strong collision happens in the same frame.
            [self sealRemoved:nodeA];
            CCLOG(@"Seal removed!");
        } key:nodeA];
    }
}

- (void)sealRemoved:(CCNode *)seal {
    // load particle effect
    CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"SealExplosion"];
    // make the particle effect clean itself up, once it is completed
    explosion.autoRemoveOnFinish = TRUE;
    // place the particle effect on the seals position
    explosion.position = seal.position;
    // add the particle effect to the same node the seal is on
    [seal.parent addChild:explosion];
    
    // finally, remove the destroyed seal
    [seal removeFromParent];
}

// if penguin speed < MIN_SPEED, catapult becomes focused by the camera.
static const float MIN_SPEED = 5.f;

- (void)update:(CCTime)delta
{
    // if speed is below minimum speed, assume this attempt is over
    //if (ccpLength(_currentPenguin.physicsBody.velocity) < MIN_SPEED){
    // if 'launched' property of _current_penguin is true this is interpreted as a signal that the attempt is over.
    if (_currentPenguin.launched) {
        [self nextAttempt];
        return;
    }
    
    int xMin = _currentPenguin.boundingBox.origin.x;
    
    if (xMin < self.boundingBox.origin.x) {
        [self nextAttempt];
        return;
    }
    
    int xMax = xMin + _currentPenguin.boundingBox.size.width;
    
    if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width)) {
        [self nextAttempt];
        return;
    }
}

- (void)nextAttempt {
    _currentPenguin = nil;
    [_contentNode stopAction:_followPenguin];
    
    CCActionMoveTo *actionMoveTo = [CCActionMoveTo actionWithDuration:1.f position:ccp(0, 0)];
    [_contentNode runAction:actionMoveTo];
}

- (void)retry {
    // reload the level
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

@end
