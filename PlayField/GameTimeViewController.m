//
//  GameTimeViewController.m
//  PlayField
//
//  Created by Emily Jeppson on 5/1/13.
//  Copyright (c) 2013 Jai. All rights reserved.
//

#import "GameTimeViewController.h"
#import "AppDelegate.h"
#import "PinchLayout.h"
#import "PlaybookCell.h"
#import "Playbook.h"

static const CGFloat kMinScale = 1.0f;
static const CGFloat kMaxScale = 3.0f;

@interface GameTimeViewController ()

@end

@implementation GameTimeViewController{
    PlaybookCell *draggingCell;
	Play *draggingPlay;
    Playbook *draggingPlaybook;
    CGRect initialDraggingFrame;
    bool upcomingPlayRemoved;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.collectionLabel.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"header-tile.jpg"]];
    self.collectionLabel.text = @" Playbooks";
    
    //disable buttons
    [self enableButtons];
    
    // data
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication]delegate];
    self.managedObjectContext = appDelegate.managedObjectContext;
    self.playBookDS = [[PlaybookDataSource alloc] initWithManagedObjectContext:self.managedObjectContext];
    self.playsDS = [[PlaysDataSource alloc] initWithManagedObjectContext:self.managedObjectContext];
    self.upcomingPlaysDS = [[UpcomingPlaysDataSource alloc] init];
    
    // set the datasources/delegates
    self.playbooksCollection.dataSource = self.playBookDS;
    self.playbooksCollection.delegate = self.playBookDS;
    self.upcomingPlaysCollection.dataSource = self.upcomingPlaysDS;
    self.upcomingPlaysCollection.delegate = self.upcomingPlaysDS;
    
    [self.playbooksCollection registerClass:[PlaybookCell class] forCellWithReuseIdentifier:@"PlaybookCell"];
    [self.upcomingPlaysCollection registerClass:[PlaybookCell class] forCellWithReuseIdentifier:@"PlayCell"];
    
    // gestures - pinch
    self.pinchOutGestureRecognizer = [[UIPinchGestureRecognizer alloc]
                                      initWithTarget:self action:@selector(handlePinchOutGesture:)];
    self.pinchOutGestureRecognizer.delegate = self;
    [self.playbooksCollection addGestureRecognizer:self.pinchOutGestureRecognizer];
    // gestures - drag & drop playbooks
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePlaybookPanning:)];
    panRecognizer.delegate = self;
    [self.playbooksCollection addGestureRecognizer:panRecognizer];
    // gestures - drag & drop upcoming plays
    UIPanGestureRecognizer *upcomingPlaysGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleUpcomingPlaysPanning:)];
    upcomingPlaysGestureRecognizer.delegate = self;
    [self.upcomingPlaysCollection addGestureRecognizer:upcomingPlaysGestureRecognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)close:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

// Pinch out - show the plays, hide the playbooks
- (void)handlePinchOutGesture: (UIPinchGestureRecognizer*)recognizer
{
    // begin pinching
   // NSLog(@"Pinching");
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"Begin pinching");
        // get the pinch point in the play books collection
        CGPoint pinchPoint = [recognizer locationInView:self.playbooksCollection];
        NSIndexPath *pinchedItem = [self.playbooksCollection indexPathForItemAtPoint:pinchPoint];
        if (pinchedItem) {
            self.currentPinchedItem = pinchedItem;
            PinchLayout *layout = [[PinchLayout alloc] init];
            layout.itemSize = CGSizeMake(200.0f, 200.0f);
            layout.minimumInteritemSpacing = 20.0f;
            layout.minimumLineSpacing = 20.0f;
            layout.sectionInset = UIEdgeInsetsMake(20.0f, 20.0f, 20.0f, 20.0f);
            layout.headerReferenceSize = CGSizeMake(0.0f, 90.0f);
            layout.pinchScale = 0.0f;

            self.playsCollection = [[UICollectionView alloc]
                                               initWithFrame:self.playbooksCollection.frame collectionViewLayout:layout];
            self.playsCollection.backgroundColor = [UIColor clearColor];
            // todo pass in the selected playbook
            self.playsCollection.delegate = self.playsDS;
            self.playsCollection.dataSource = self.playsDS;
            self.playsCollection.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.playsCollection.backgroundColor = [UIColor darkGrayColor];
            self.playsCollection.scrollEnabled = YES;
            
            [self.playsCollection registerClass:[PlaybookCell class] forCellWithReuseIdentifier:@"PlayCell"];
            [self.view addSubview:self.playsCollection];
            // gestures - pinch to close
            UIPinchGestureRecognizer *recognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchInGesture:)];
            recognizer.delegate = self;
            [self.playsCollection addGestureRecognizer:recognizer];
            // gestures - drag & drop
            // gestures - drag
            UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePlayPanning:)];
            panRecognizer.delegate = self;
            [self.playsCollection addGestureRecognizer:panRecognizer];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (self.currentPinchedItem) {
            CGFloat theScale = recognizer.scale;
            theScale = MIN(theScale, kMaxScale);
            theScale = MAX(theScale, kMinScale);
            CGFloat theScalePct = (theScale - kMinScale) / (kMaxScale - kMinScale);
    
            PinchLayout *layout = (PinchLayout*)_playsCollection.collectionViewLayout;
            layout.pinchScale = theScalePct; layout.pinchCenter =
            [recognizer locationInView:self.playsCollection];
            // fade out the playbooks collection
            self.playbooksCollection.alpha = 1.0f - theScalePct; }
    } else {
        //NSLog(@"Pinching ended");
        if (self.currentPinchedItem) {
            Playbook *playbook = [self.playBookDS.fetchedResultsController objectAtIndexPath:self.currentPinchedItem];
            self.collectionLabel.text = [NSString stringWithFormat:@"Plays for %@",playbook.name];
            // hide the old collection
            PinchLayout *layout = (PinchLayout*)_playsCollection.collectionViewLayout;
            layout.pinchScale = 1.0f;
            self.playbooksCollection.alpha = 0.0f; }
    }
}

// hide the plays, show the playbooks
- (void)handlePinchInGesture: (UIPinchGestureRecognizer*)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.playbooksCollection.alpha = 0.0f;
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGFloat theScale = 1.0f / recognizer.scale;
        theScale = MIN(theScale, kMaxScale);
        theScale = MAX(theScale, kMinScale);
        CGFloat theScalePct = 1.0f - ((theScale - kMinScale) / (kMaxScale - kMinScale));
        PinchLayout *layout = (PinchLayout*)self.playsCollection.collectionViewLayout ;
        layout.pinchScale = theScalePct;
        layout.pinchCenter = [recognizer locationInView:self.playbooksCollection];
        self.playbooksCollection.alpha = 1.0f - theScalePct;
    } else {
        self.collectionLabel.text = @"Playbooks";
        self.playbooksCollection.alpha = 1.0f;
        [self.playsCollection removeFromSuperview];
        self.playsCollection = nil;
        self.currentPinchedItem = nil;
    }
}

// drag & drop for plays to upcoming plays
- (void)handlePlayPanning:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // get the pinch point in the play books collection
        CGPoint pinchPoint = [recognizer locationInView:self.playsCollection];
        NSIndexPath *pannedItem = [self.playsCollection indexPathForItemAtPoint:pinchPoint];
        if (pannedItem) {
            self.currentPannedItem = pannedItem;

            initialDraggingFrame.origin = pinchPoint;
            initialDraggingFrame.size.height = 150;
            initialDraggingFrame.size.width = 150;
            // center the cell
            initialDraggingFrame.origin.x -= (initialDraggingFrame.size.width / 2);
            initialDraggingFrame.origin.y -= (8 + self.playsCollection.contentOffset.y);
            // have we scrolled?
//            initialDraggingFrame.origin.y -= [self.playsCollection contentOffset].y;
            initialDraggingFrame.origin.y += (initialDraggingFrame.size.height);
            
            // add the cell to the view
            draggingPlay = [self.playsDS.fetchedResultsController objectAtIndexPath:pannedItem];
            draggingCell = [[PlaybookCell alloc] initWithFrame:initialDraggingFrame name:draggingPlay.name];
            [self.view addSubview:draggingCell];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if(self.currentPannedItem == nil || draggingPlay == nil){
            return;
        }
        //NSLog(@"Dragging changed");
        // move the cell around
        CGPoint translation = [recognizer translationInView:self.playsCollection];
        CGRect newFrame = initialDraggingFrame;
        newFrame.origin.x += translation.x;
        newFrame.origin.y += translation.y;
        draggingCell.frame = newFrame;
        //move the placeholder
        [self addDraggedCell:recognizer draggedItem:draggingPlay];
    } else {
        if(self.currentPannedItem == nil || draggingPlay == nil){
            return;
        }
        //NSLog(@"dragging ended");
        // add the cell to the appropriate place
        [self addDraggedCell:recognizer draggedItem:draggingPlay];
        
        [draggingCell removeFromSuperview];
        draggingCell = nil;
        draggingPlay = nil;
        [self enableButtons];
    }
}
    
- (void)addDraggedCell:(UIPanGestureRecognizer*)sender draggedItem:(NSObject*) draggedItem {
        // add the cell to the appropriate place
        CGPoint translation = [sender translationInView:self.upcomingPlaysCollection];
        CGRect newFrame = initialDraggingFrame;
        newFrame.origin.x += translation.x;
        newFrame.origin.y += translation.y;
        newFrame.origin.x += self.upcomingPlaysCollection.contentOffset.x;
        NSIndexPath *landingPoint = [self.upcomingPlaysCollection indexPathForItemAtPoint:newFrame.origin];
    
        if(landingPoint){
            [self.upcomingPlaysDS.upcomingPlays removeObject:draggingPlay];
            //Play *landingItem = self.upcomingPlaysDS.upcomingPlays[landingPoint.item];
            int index = landingPoint.item;
            if(index > 0){
                index--;
            }
            [self.upcomingPlaysDS.upcomingPlays insertObject:draggedItem atIndex:index];
        } else if(newFrame.origin.x > 0 && newFrame.origin.y > 0 && newFrame.origin.x < self.upcomingPlaysCollection.frame.size.width && newFrame.origin.y < self.upcomingPlaysCollection.frame.size.height){
            [self.upcomingPlaysDS.upcomingPlays removeObject:draggedItem];
            [self.upcomingPlaysDS.upcomingPlays addObject:draggedItem];
        } else {
            //NSLog(@"Not dragging over upcoming plays %f %f", newFrame.origin.x, newFrame.origin.y);
        }
    [self.upcomingPlaysCollection reloadData];
        
}

- (void)handlePlaybookPanning:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // get the pinch point in the play books collection
        CGPoint pinchPoint = [recognizer locationInView:self.playbooksCollection];
        NSIndexPath *pannedItem = [self.playbooksCollection indexPathForItemAtPoint:pinchPoint];
        if (pannedItem) {
            self.currentPannedItem = pannedItem;
            
            initialDraggingFrame.origin = pinchPoint;
            initialDraggingFrame.size.height = 150;
            initialDraggingFrame.size.width = 150;
            // center the cell
            initialDraggingFrame.origin.x -= (initialDraggingFrame.size.width / 2);
            initialDraggingFrame.origin.y -= (8 + self.playsCollection.contentOffset.y);
            // have we scrolled?
            initialDraggingFrame.origin.y -= [self.playbooksCollection contentOffset].y;
            initialDraggingFrame.origin.y += (initialDraggingFrame.size.height);
            
            // add the cell to the view
            draggingPlaybook = [self.playBookDS.fetchedResultsController objectAtIndexPath:pannedItem];
            draggingCell = [[PlaybookCell alloc] initWithFrame:initialDraggingFrame name:draggingPlaybook.name];
            [self.view addSubview:draggingCell];
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if(self.currentPannedItem == nil || draggingPlaybook == nil){
            return;
        }
        //NSLog(@"Dragging changed");
        // move the cell around
        CGPoint translation = [recognizer translationInView:self.playbooksCollection];
        CGRect newFrame = initialDraggingFrame;
        newFrame.origin.x += translation.x;
        newFrame.origin.y += translation.y;
        draggingCell.frame = newFrame;
        //move the placeholder
        [self addDraggedCell:recognizer draggedItem:draggingPlaybook];
    } else {
        if(self.currentPannedItem == nil || draggingPlaybook == nil){
            return;
        }
        [self.upcomingPlaysDS.upcomingPlays removeObject:draggingPlaybook];
        // TODO get all the plays associated with the current playbook and add them
        id <NSFetchedResultsSectionInfo> section = self.playsDS.fetchedResultsController.sections[0];
        for(Play *play in [section objects]){
            [self addDraggedCell:recognizer draggedItem:play];
        }
        
        [draggingCell removeFromSuperview];
        draggingCell = nil;
        draggingPlaybook = nil;
        [self enableButtons];
    }
}

- (void)handleUpcomingPlaysPanning:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // get the pinch point in the play books collection
        CGPoint pinchPoint = [recognizer locationInView:self.upcomingPlaysCollection];
        NSIndexPath *pannedItem = [self.upcomingPlaysCollection indexPathForItemAtPoint:pinchPoint];
        if (pannedItem) {
            self.currentPannedItem = pannedItem;
            
            initialDraggingFrame.origin = pinchPoint;
            initialDraggingFrame.size.height = 150;
            initialDraggingFrame.size.width = 150;
            // center the cell
            initialDraggingFrame.origin.x += (75 + initialDraggingFrame.size.width);
            // have we scrolled?
            initialDraggingFrame.origin.x -= (self.upcomingPlaysCollection.contentOffset.x);
            //initialDraggingFrame.origin.y -= (self.upcomingPlaysCollection.contentOffset.y);
            initialDraggingFrame.origin.y -= (initialDraggingFrame.size.height / 2);
            
            // add the cell to the view
            
            draggingPlay = [self.upcomingPlaysDS.upcomingPlays objectAtIndex:pannedItem.item];
            draggingCell = [[PlaybookCell alloc] initWithFrame:initialDraggingFrame name:draggingPlay.name];
            [self.view addSubview:draggingCell];
            upcomingPlayRemoved = NO;
            //NSLog(@"Finding dragging play at index %d %@", pannedItem.item, draggingPlay);
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if(self.currentPannedItem == nil || draggingPlay == nil){
            return;
        }
        //NSLog(@"Dragging changed");
        // move the cell around
        CGPoint translation = [recognizer translationInView:self.upcomingPlaysCollection];
        CGRect newFrame = initialDraggingFrame;
        newFrame.origin.x += translation.x;
        newFrame.origin.y += translation.y;
        draggingCell.frame = newFrame;
        
        //remove it if needed
        CGPoint location = [recognizer locationInView:self.upcomingPlaysCollection];
        NSLog(@"Location: %f Height: %f", location.y, self.upcomingPlaysCollection.frame.size.height);
        if(upcomingPlayRemoved == NO && location.y > (self.upcomingPlaysCollection.frame.size.height)){
            [self.upcomingPlaysDS.upcomingPlays removeObject:draggingPlay];
            [self.upcomingPlaysCollection reloadData];
            upcomingPlayRemoved = YES;
        } else if(location.y <= (self.upcomingPlaysCollection.frame.size.height)){
            // add it back if needed
            [self addDraggedCell:recognizer draggedItem:draggingPlay];
            upcomingPlayRemoved = NO;
        }
    } else {
        if(self.currentPannedItem == nil || draggingPlay == nil){
            return;
        }
        [draggingCell removeFromSuperview];
        draggingCell = nil;
        draggingPlay = nil;
        self.currentPannedItem = nil;
        [self enableButtons];
    }
}


#pragma UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


#pragma GameTimeViewController 
- (void) enableButtons{
    if(self.upcomingPlaysDS.upcomingPlays.count > 0){
        self.nextPlayButton.enabled = YES;
        self.removeAllButton.enabled = YES;
        self.nextPlayButton.alpha = 1.0;
        self.removeAllButton.alpha = 1.0;
    } else {
        self.nextPlayButton.enabled = NO;
        self.removeAllButton.enabled = NO;
        self.nextPlayButton.alpha = 0.7f;
        self.removeAllButton.alpha = 0.7f;
    }
}

- (IBAction)loadNextPlay:(id)sender {
    // get the first play from upcoming plays
    if(self.upcomingPlaysDS.upcomingPlays.count > 0){
        Play *firstPlay = self.upcomingPlaysDS.upcomingPlays[0];
        
        CGRect frame = CGRectMake(self.currentPlayView.frame.origin.x + 2, self.currentPlayView.frame.origin.y, 150, 150);
        UICollectionViewCell *cell = [[PlaybookCell alloc] initWithFrame:frame name:firstPlay.name];
        [self.currentPlayView addSubview:cell];
        [self.upcomingPlaysDS.upcomingPlays removeObject:firstPlay];
        [self.upcomingPlaysCollection reloadData];
        [self enableButtons];
    }
}

- (IBAction)removeAllPlays:(id)sender {
    [self.upcomingPlaysDS.upcomingPlays removeAllObjects];
    [self.upcomingPlaysCollection reloadData];
    [self enableButtons];
}
@end
