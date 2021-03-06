//
//  PlaybookDataSourceViewController.m
//  PlayField
//
//  Created by Emily Jeppson on 5/1/13.
//  Copyright (c) 2013 Jai. All rights reserved.
//

#import "PlaybookDataSource.h"
#import "PlaybookCell.h"
#import "Playbook.h"

@interface PlaybookDataSource ()

@end

@implementation PlaybookDataSource

-(id) initWithManagedObjectContext: (NSManagedObjectContext*) managedObjectContext{
    if((self=[super init])){
        self.managedObjectContext = managedObjectContext;
    }
    return self;
}


#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (NSInteger)numberOfSectionsInCollectionView: (UICollectionView *)collectionView {
    return [[self.fetchedResultsController sections] count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"PlaybookCell" forIndexPath:indexPath];
    
    PlaybookCell *playbookCell = (PlaybookCell *) cell;
    Playbook *playbook = [self.fetchedResultsController objectAtIndexPath:indexPath];
    playbookCell = [playbookCell initWithFrame:playbookCell.frame playbook:playbook];
    return playbookCell;
}

#pragma mark – UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CGSize retval = CGSizeMake(150, 150);
    return retval;
}

- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10, 10, 10, 10);
}

#pragma mark – Database

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Playbook" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    // Offense or defense
    if(self.offenseOrDefense){
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(type == %@)", self.offenseOrDefense];
        [fetchRequest setPredicate:predicate];
    } else{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:
                                  @"(type != 'hidden')", self.offenseOrDefense];
        [fetchRequest setPredicate:predicate];
    }
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"displayOrder" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    _fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    [self fatalCoreDataError:error];
	}
    
    return _fetchedResultsController;
}

- (void) fatalCoreDataError:(NSError *)error
{
    NSLog(@"*** Fatal error in %s:%d\n%@\n%@", __FILE__, __LINE__, error, [error userInfo]);
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internal Error", nil) message:NSLocalizedString(@"There was a fatal error in the app and it cannot continue.\n\nPress OK to terminate the app. Sorry for the inconvenience.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    [alertView show];
}

// for re-ordering playbooks
- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath {
    [TestFlight passCheckpoint:[NSMutableString stringWithFormat:@"PlaybookDataSource - Reordering playbooks..."]];
    NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithArray:self.fetchedResultsController.fetchedObjects];
    id object = [mutableArray objectAtIndex:fromIndexPath.item];
    [mutableArray removeObjectAtIndex:fromIndexPath.item];
    [mutableArray insertObject:object atIndex:toIndexPath.item];
    
    for(int i=0; i<mutableArray.count; i++){
        Playbook *playbook = (Playbook*)mutableArray[i];
        playbook.displayOrder = [NSNumber numberWithInt:i];
    }
    // save the new order
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        [self fatalCoreDataError:error];
        return;
    }
}
@end
