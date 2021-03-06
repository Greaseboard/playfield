//
//  HelloWorldLayer.m
//  PlayField
//
//  Created by Jai on 2/11/13.
//  Copyright Jai 2013. All rights reserved.
//


#import "HelloWorldLayer.h"
#import "AppDelegate.h"
#import "PlaySprite.h"
#import "SpritePoint.h"

#pragma mark - HelloWorldLayer

@implementation HelloWorldLayer
{
    bool positioning;
    PlaySprite *selPlayerSprite;
    CCMenuItem *trashMenuItem;
    CCSprite *background;
    float currentBlue;
    float currentRed;
    float currentGreen;
    bool drawing;
    
    CCMenu *menu;
    CCMenuItem *blueCircleItem;
    CCMenuItem *redCircleItem;
    CCMenuItem *yellowCircleItem;
    CCMenuItem *whiteCircleItem;
    CCMenuItem *playMenuItem;
    CCMenuItem *resetMenuItem;
}

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [[HelloWorldLayer alloc] init];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	if( (self=[super init] )) {
        //CGSize winSize = [CCDirector sharedDirector].winSize;
        //glClearColor(0, 255, 0, 255);
        // Set Background
        [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGB565];
        background = [CCSprite spriteWithFile:@"field.jpg"];
        background.anchorPoint = ccp(0,0);
        [self addChild:background z:-1];
        [CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_Default];
        
        // Standard method to create a button
        playMenuItem = [CCMenuItemImage itemWithNormalImage:@"bttn-play.png" selectedImage:@"bttn-play.png" target:self selector:@selector(playButtonTapped:)];
        resetMenuItem = [CCMenuItemImage itemWithNormalImage:@"bttn-replay.png" selectedImage:@"bttn-replay.png" target:self selector:@selector(resetButtonTapped:)];
        CCMenuItem *positionMenuItem = [CCMenuItemImage itemWithNormalImage:@"bttn-move.png" selectedImage:@"bttn-move.png" target:self selector:@selector(positionButtonTapped:)];
        
        blueCircleItem = [CCMenuItemImage itemWithNormalImage:@"blueCircle.png" selectedImage:@"blueCircle-s.png" target:self selector:@selector(blueCircleTapped:)];
        redCircleItem = [CCMenuItemImage itemWithNormalImage:@"redCircle.png" selectedImage:@"redCircle-s.png" target:self selector:@selector(redCircleTapped:)];
        yellowCircleItem = [CCMenuItemImage itemWithNormalImage:@"yellowCircle.png" selectedImage:@"yellowCircle-s.png" target:self selector:@selector(yellowCircleTapped:)];
        whiteCircleItem = [CCMenuItemImage itemWithNormalImage:@"whiteCircle.png" selectedImage:@"whiteCircle-s.png" target:self selector:@selector(whiteCircleTapped:)];
        
        trashMenuItem = [CCMenuItemImage itemWithNormalImage:@"trash.png" selectedImage:@"trash.png" target:self selector:@selector(trashButtonTapped:)];
        playMenuItem.position = ccp(60, 50);
        resetMenuItem.position = ccp(130,50);
        positionMenuItem.position = ccp(200,50);
        whiteCircleItem.position = ccp(290,50);
        redCircleItem.position = ccp(360,50);
        yellowCircleItem.position = ccp(430,50);
        blueCircleItem.position = ccp(520,50);
        trashMenuItem.position = ccp(640,30);
        menu = [CCMenu menuWithItems:playMenuItem, resetMenuItem, positionMenuItem, whiteCircleItem, redCircleItem, yellowCircleItem, blueCircleItem, trashMenuItem, nil];
        menu.position = ccp(0,15);
        [self addChild:menu];
        [menu setVisible:false];
        
        self.movableSprites = [[NSMutableOrderedSet alloc] init];
        positioning = false;
        [self whiteCircleTapped:self];
    }
    
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    
    return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
}

- (void)selectSpriteForTouch:(CGPoint)touchLocation {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld -  selectSpritForTouch"]];
    PlaySprite *newPlayerSprite = nil;
    
    int xDistance = 0;
    int yDistance = 0;
    for (PlaySprite *ps in self.movableSprites) {
        int xDifference = abs( CGRectGetMidX(ps.sprite.boundingBox) - touchLocation.x );
        int yDifference = abs ( CGRectGetMidY(ps.sprite.boundingBox) - touchLocation.y );
        //[TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld -  selectSpritForTouch2 %i %i", xDifference, yDifference]];
        if (CGRectContainsPoint(ps.sprite.boundingBox, touchLocation) ) { // if it's within the box
            if(!newPlayerSprite){
                //[TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld -  selectSpritForTouch3 - setting sprite %i %i", xDifference, yDifference]];
                newPlayerSprite = ps;
                xDistance = xDifference;
                yDistance = yDifference;
            } // if there are 2 sprites in the same place, get the one that is closest to the touch point instead of the first one found
            else if(xDifference < xDistance && yDifference < yDistance){
                    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld -  selectSpritForTouch4 - using second point"]];
                    newPlayerSprite = ps;
                    xDistance = xDifference;
                    yDistance = yDifference;
            }
        }
    }
    selPlayerSprite = newPlayerSprite;
    [selPlayerSprite.sprite setPosition: touchLocation];
    //[selPlayerSprite.sprite setAnchorPoint:ccp(0.5f, 0.5f)];
        
    //remove objects each time the player makes a new path
    [selPlayerSprite resetPath];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld -  ccTouchBegan"]];
    if(!positioning) {
        [self resetScene];
    }
    
    CGPoint touchLocation = [self convertTouchToNodeSpace:touch];
    if( drawing ) {
        [self addPlayerSpriteWithImage:nil andPosition:touchLocation];
        [self selectSpriteForTouch:touchLocation];
        if( selPlayerSprite.imageString != nil) {
            selPlayerSprite = nil; // If drawing, don't allow user to grab sprite with image.
        }
    } else {
        [self selectSpriteForTouch:touchLocation];
    }
    
    selPlayerSprite.red = currentRed;
    selPlayerSprite.blue = currentBlue;
    selPlayerSprite.green = currentGreen;
    
    return TRUE;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    
    CGPoint newTouchLocation = [self convertTouchToNodeSpace:touch];
    
    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    if(!positioning) {
        [selPlayerSprite.toucharray addObject:NSStringFromCGPoint(newTouchLocation)];
        [selPlayerSprite.toucharray addObject:NSStringFromCGPoint(oldTouchLocation)];
    }
    
    CGPoint translation = ccpSub(newTouchLocation, oldTouchLocation);
    if (selPlayerSprite) {
        CGPoint newPos = ccpAdd(selPlayerSprite.sprite.position, translation);
        //NSLog(@"TouchLocation newPosition %f,%f", newPos.x, newPos.y);
        //[selPlayerSprite repositionSpriteWithPosition:newPos];
        selPlayerSprite.sprite.position = newPos;
    }
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event{
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - ccTouchEnded"]];
    if(positioning) {
        CGPoint newPosition = [self convertTouchToNodeSpace:touch];
        [selPlayerSprite repositionSpriteWithPosition:newPosition ];
        
        if (CGRectIntersectsRect(selPlayerSprite.sprite.boundingBox, trashMenuItem.boundingBox)) {
            [self removePlaySprite:selPlayerSprite];
        }
    } else {
        // Move Sprint to beginning of line
        if( [selPlayerSprite.toucharray count] > 0 ) {
            CGPoint origPosition = CGPointFromString( [selPlayerSprite.toucharray objectAtIndex:0] );
            selPlayerSprite.sprite.position = origPosition;
            selPlayerSprite.maxIndex = [selPlayerSprite.toucharray count];
            [selPlayerSprite saveSpritePoints];
        }
    }
}

- (void)draggingStarted:(UIPanGestureRecognizer *)recognizer forItemWithName:(NSString *)name
{
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - dragging started for %@", name]];
    if(name){
        NSString *imageName;
        imageName = [name stringByAppendingString:@".png"];

        UIView *view = [[CCDirector sharedDirector] view];
        CGPoint touchLocation = [recognizer locationInView:view];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        NSLog(@"TouchLocation start %f,%f", touchLocation.x, touchLocation.y);
    
        [self addPlayerSpriteWithImage:imageName andPosition:touchLocation];
        selPlayerSprite = [self.movableSprites lastObject];
    }
}

- (void)draggingChanged:(UIPanGestureRecognizer *)recognizer{
    UIView *view = [[CCDirector sharedDirector] view];
    CGPoint touchLocation = [recognizer translationInView:view];
    touchLocation.y = touchLocation.y * -1;
    [self panForTranslation:touchLocation];
    [recognizer setTranslation:CGPointZero inView:view];
}

- (void)draggingEnded:(UIPanGestureRecognizer *)recognizer{
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld -  draggingEnded"]];
    UIView *view = [[CCDirector sharedDirector] view];
    CGPoint newPosition = [recognizer translationInView:view];
    [self panForTranslation:newPosition];
    
    if (CGRectIntersectsRect(selPlayerSprite.sprite.boundingBox, trashMenuItem.boundingBox)) {
        [self removePlaySprite:selPlayerSprite];
    }
}

- (void)panForTranslation:(CGPoint)translation {
    if (selPlayerSprite) {
        CGPoint newPos = ccpAdd(selPlayerSprite.sprite.position, translation);
        //NSLog(@"TouchLocation newPosition %f,%f", newPos.x, newPos.y);
        [selPlayerSprite repositionSpriteWithPosition:newPos];
        //selPlayerSprite.sprite.position = newPos;
    }
}

- (void)draw {
    glLineWidth(3.0f);
    for (PlaySprite *ps in self.movableSprites) {
        for (int i = 0; i < [ps.toucharray count]; i+=2) {
            ccDrawColor4B(ps.red, ps.green, ps.blue, 255);
            CGPoint start = CGPointFromString([ps.toucharray objectAtIndex:i]);
            CGPoint end = CGPointFromString([ps.toucharray objectAtIndex:i+1]);
            ccDrawLine(start, end);
        }
    }
}

- (void) resetScene{
    for(PlaySprite *ps in self.movableSprites) {
        [ps.sprite stopAllActions];
        [ps resetSprite];
    }
}

- (void)playButtonTapped:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - playButtonTapped"]];
    for (PlaySprite *ps in self.movableSprites) {
        [ps.sprite stopAllActions];
        [ps moveSpriteWithSpeed:150];
    }
}

- (void)resetButtonTapped:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - resetButtonTapped"]];
    [self resetScene];
}

- (void)blueCircleTapped:(id)sender {
    [self resetColorButton];
    [blueCircleItem selected];
    drawing = true;
    currentBlue = 255;
    currentGreen = 0;
    currentRed = 0;
}

- (void)redCircleTapped:(id)sender {
    [self resetColorButton];
    [redCircleItem selected];
    drawing = false;
    currentBlue = 0;
    currentGreen = 0;
    currentRed = 255;
}

- (void)yellowCircleTapped:(id)sender {
    [self resetColorButton];
    [yellowCircleItem selected];
    drawing = false;
    currentBlue = 0;
    currentGreen = 255;
    currentRed = 255;
}

- (void)whiteCircleTapped:(id)sender {
    [self resetColorButton];
    [whiteCircleItem selected];
    drawing = false;
    currentBlue = 255;
    currentGreen = 255;
    currentRed = 255;
}

- (void)resetColorButton {
    [whiteCircleItem unselected];
    [blueCircleItem unselected];
    [yellowCircleItem unselected];
    [redCircleItem unselected];
}

- (void)trashButtonTapped:(id)sender {
    NSMutableArray *lines = [[NSMutableArray alloc] init];
    for (PlaySprite *ps in self.movableSprites) {
        if( ps.imageString == nil) {
            [lines addObject:ps];
        }
    }
    for( NSObject *o in lines ) {
        [self removePlaySprite:(PlaySprite *)o];
    }
}

- (void)positionButtonTapped:(id)sender {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - positionButtonTapped"]];
    positioning = !positioning;
    if( !positioning ) {
        for(PlaySprite *ps in self.movableSprites) {
            [ps.sprite stopAllActions];
            [ps.sprite runAction:[CCRotateTo actionWithDuration:0.1 angle:0]];
        }
        [self whiteCircleTapped:nil]; // Set default color after positioning.
    } else {
        [self resetScene];
        for(PlaySprite *ps in self.movableSprites) {
            [self actionSpriteForPositioning:ps.sprite];
        }
    }
    [redCircleItem setVisible:!positioning];
    [blueCircleItem setVisible:!positioning];
    [yellowCircleItem setVisible:!positioning];
    [whiteCircleItem setVisible:!positioning];
    [playMenuItem setVisible:!positioning];
    [resetMenuItem setVisible:!positioning];
    drawing = false;
}

- (void) actionSpriteForPositioning:(CCSprite *)pSprite
{
    CCRotateTo * rotLeft = [CCRotateBy actionWithDuration:0.1 angle:-12.0];
    CCRotateTo * rotCenter = [CCRotateBy actionWithDuration:0.1 angle:0.0];
    CCRotateTo * rotRight = [CCRotateBy actionWithDuration:0.1 angle:12.0];
    CCSequence * rotSeq = [CCSequence actions:rotLeft, rotCenter, rotRight, rotCenter, nil];
    [pSprite runAction:[CCRepeatForever actionWithAction:rotSeq]];
}

- (void) addDefaultPlay
{
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - addDefaultPlay"]];
    
    // Offense
    int centerH = 350;
    int centerV = 300;
    [self addPlayerSpriteWithImage:@"Offense-C.png" andPosition:ccp(centerH,centerV)];    // Center
    [self addPlayerSpriteWithImage:@"Offense-RG.png" andPosition:ccp(centerH+50,centerV)];
    [self addPlayerSpriteWithImage:@"Offense-RT.png" andPosition:ccp(centerH+100,centerV)];
    [self addPlayerSpriteWithImage:@"Offense-LG.png" andPosition:ccp(centerH-50,centerV)];
    [self addPlayerSpriteWithImage:@"Offense-LT.png" andPosition:ccp(centerH-100,centerV)];
    [self addPlayerSpriteWithImage:@"Offense-Y.png" andPosition:ccp(centerH-300,centerV-20)];
    [self addPlayerSpriteWithImage:@"Offense-1.png" andPosition:ccp(centerH,centerV-35)]; // Quarterback
    [self addPlayerSpriteWithImage:@"Offense-2.png" andPosition:ccp(centerH,centerV-90)];
    [self addPlayerSpriteWithImage:@"Offense-3.png" andPosition:ccp(centerH,centerV-140)];
    [self addPlayerSpriteWithImage:@"Offense-TE.png" andPosition:ccp(centerH+150,centerV)];
    [self addPlayerSpriteWithImage:@"Offense-Z.png" andPosition:ccp(centerH+320,centerV)];
    
    // Defense
    centerH = 350;
    centerV = 350;
    [self addPlayerSpriteWithImage:@"Defense-LB.png" andPosition:ccp(centerH,centerV+117)];
    [self addPlayerSpriteWithImage:@"Defense-LB.png" andPosition:ccp(centerH+115,centerV+75)];
    [self addPlayerSpriteWithImage:@"Defense-DE.png" andPosition:ccp(centerH+215,centerV+15)];
    [self addPlayerSpriteWithImage:@"Defense-LB.png" andPosition:ccp(centerH-90,centerV+75)];
    [self addPlayerSpriteWithImage:@"Defense-DE.png" andPosition:ccp(centerH-150,centerV)];
    [self addPlayerSpriteWithImage:@"Defense-DL.png" andPosition:ccp(centerH-50,centerV+15)];
    [self addPlayerSpriteWithImage:@"Defense-DL.png" andPosition:ccp(centerH+65,centerV)];
    [self addPlayerSpriteWithImage:@"Defense-C.png" andPosition:ccp(centerH+320,centerV+50)];
    [self addPlayerSpriteWithImage:@"Defense-SS.png" andPosition:ccp(centerH+225,centerV+117)];
    [self addPlayerSpriteWithImage:@"Defense-C.png" andPosition:ccp(centerH-300,centerV+50)];
    [self addPlayerSpriteWithImage:@"Defense-FS.png" andPosition:ccp(centerH,centerV+252)];
}

- (void) addDefaultDrill
{
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - addDefaultDrill"]];
    
    // Offense
    int centerH = 350;
    int centerV = 300;
    [self addPlayerSpriteWithImage:@"Offense-1.png" andPosition:ccp(centerH,centerV)];    // Player
    [self addPlayerSpriteWithImage:@"Cone.png" andPosition:ccp(centerH,centerV + 100)];    // Cone
}

- (void) addPlayerSpriteWithImage:(NSString *)pImage andPosition:(CGPoint)pPosition {
    PlaySprite *ps = [NSEntityDescription insertNewObjectForEntityForName:@"PlaySprite" inManagedObjectContext:self.managedObjectContext];
    ps = [ps initWithImage:pImage andPosition:pPosition];
    ps.play = self.play;
    [self addChild: ps.sprite ];
    [self.movableSprites addObject:ps];
    if(positioning) {
        [self actionSpriteForPositioning:ps.sprite];
    }
}

- (void) loadPlaySprites
{
    for(PlaySprite *ps in self.play.playSprite) {
        [self loadPlaySprite:ps];
    }
}

- (void) loadPlaySprite:(PlaySprite *)pPlaySprite {
    pPlaySprite = [pPlaySprite initFromDatabase];
    [self addChild:pPlaySprite.sprite];
    [self.movableSprites addObject:pPlaySprite];
}

- (void) removePlaySprite:(PlaySprite *)pPlaySprite {
    [self removeChild:pPlaySprite.sprite];
    [self.movableSprites removeObject:pPlaySprite];
    [self.managedObjectContext deleteObject:pPlaySprite];
}

- (void) setCurrentPlay:(Play *)pPlay {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - setCurrentPlay"]];
    for(PlaySprite *ps in self.movableSprites) {
        [self removeChild:ps.sprite];
    }
    [self.movableSprites removeAllObjects];
    self.play = pPlay;
    if( [self.play.playSprite count] == 0 ) {
        // Add default play.
        if( [self.play.type isEqualToString:@"Drill"] ) {
            [self addDefaultDrill];
        } else {
            [self addDefaultPlay ];
        }
    } else {
        [self loadPlaySprites];
    }
    
    [menu setVisible:true];
}

//- (void) addItemSprite:(NSString *)itemName
//{
//    [self addPlayerSpriteWithImage:itemName andPosition:ccp(350,75)];
//}

- (NSData*) screenshotUIImage:(CGSize) displaySize forWinSize: (CGSize) winSize
{
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"HelloWorld - screenshotUIImage"]];
    [menu setVisible:false];
    CCScene *scene = [[CCDirector sharedDirector] runningScene];
    CCNode *startNode = [scene.children objectAtIndex:0];
    
	[CCDirector sharedDirector].nextDeltaTimeZero = YES;
    
    CCRenderTexture* rtx =
    [CCRenderTexture renderTextureWithWidth:winSize.width
                                     height:winSize.height];
    [rtx begin];
    [startNode visit];
    [rtx end];
    
    UIImage *outputImage = [rtx getUIImage];
    
    // uncomment next line to save to photo album (for testing)
    //UIImageWriteToSavedPhotosAlbum(outputImage,nil,NULL,NULL);
    
    // convert the UIImage to NSData
    [menu setVisible:true];
    return UIImageJPEGRepresentation(outputImage, 1.0 ); //you can use PNG too
}

@end
