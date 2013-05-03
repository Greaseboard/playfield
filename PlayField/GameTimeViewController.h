//
//  GameTimeViewController.h
//  PlayField
//
//  Created by Emily Jeppson on 5/1/13.
//  Copyright (c) 2013 Jai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlaybookDataSource.h"
#import "PlaysDataSource.h"

@interface GameTimeViewController : UIViewController
- (IBAction)close:(id)sender;

// collections
@property (strong, nonatomic) IBOutlet UICollectionView *playbooksCollection;
@property (strong, nonatomic) IBOutlet UICollectionView *playsCollection;
@property (strong, nonatomic) IBOutlet UICollectionView *upcomingPlaysCollection;
@property (strong, nonatomic) PlaybookDataSource *playBookDS;
@property (strong, nonatomic) PlaysDataSource *playsDS;

// gestures - pinching & panning
@property (nonatomic, strong) UIPinchGestureRecognizer *pinchOutGestureRecognizer;
@property (nonatomic, strong) NSIndexPath *currentPinchedItem;
@property (nonatomic, strong) NSIndexPath *currentPannedItem;

// object context
@property (retain, nonatomic) NSManagedObjectContext *managedObjectContext;

@end