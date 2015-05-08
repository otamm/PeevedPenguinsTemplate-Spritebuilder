//
//  Gameplay.h
//  PeevedPenguins
//
//  Created by Otavio Monteagudo on 4/10/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "CCSprite.h"
#import "CCNode.h"
#import "CCPhysics+ObjectiveChipmunk.h"

@interface Gameplay : CCNode <CCPhysicsCollisionDelegate> // delegates control to CCPhysicsCollision at specific moments.
/*
 Delegation is a simple and powerful pattern in which one object in a program acts on behalf of, or in coordination with, another object. The delegating object keeps a reference to the other object&mdash;the delegate&mdash;and at the appropriate time sends a message to it. The message informs the delegate of an event that the delegating object is about to handle or has just handled. The delegate may respond to the message by updating the appearance or state of itself or other objects in the application, and in some cases it can return a value that affects how an impending event is handled. The main value of delegation is that it allows you to easily customize the behavior of several objects in one central object.
 */

@end
