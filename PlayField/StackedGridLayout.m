//
//  StackedGridLayout.m
//  Flicker Search
//
//  Created by Emily Jeppson on 2/14/13.
//  Copyright (c) 2013 Emily. All rights reserved.
//

#import "StackedGridLayout.h"

@interface StackedGridLayout () {
    __weak id <StackedGridLayoutDelegate> _myDelegate;
    NSMutableArray *_sectionData;
    CGFloat _height;
}
@end

@implementation StackedGridLayout

- (void)prepareLayout { // 1
    [super prepareLayout];
    
    // 2
    _myDelegate = (id <StackedGridLayoutDelegate>) self.collectionView.delegate;
    _sectionData = [NSMutableArray new];
    _height = 0.0f;
    // 3
    CGPoint currentOrigin = CGPointZero;
    NSInteger numberOfSections = self.collectionView.numberOfSections;
    // 4
    for (NSInteger i = 0; i < numberOfSections; i++) { // 5
        _height += self.headerHeight; currentOrigin.y = _height;
        // 6
        NSInteger numberOfColumns =
                            [_myDelegate collectionView:self.collectionView
                             layout:self numberOfColumnsInSection:i];
        NSInteger numberOfItems = [self.collectionView numberOfItemsInSection:i];
        UIEdgeInsets itemInsets = [_myDelegate collectionView:self.collectionView
                             layout:self itemInsetsForSectionAtIndex:i];
        // 7
        StackedGridLayoutSection *section = [[StackedGridLayoutSection alloc] initWithOrigin:currentOrigin
                                                                                       width:self.collectionView.bounds.size.width columns:numberOfColumns
                                                                                  itemInsets:itemInsets];
        // 8
        for (NSInteger j = 0; j < numberOfItems; j++) { // 9
            NSInteger columnIndex = [_myDelegate findColumnForIndex:j];
            CGFloat itemWidth = ([section widthForItemAtColumnIndex:columnIndex] - section.itemInsets.left -
                                 section.itemInsets.right);
            NSIndexPath *itemIndexPath = [NSIndexPath indexPathForItem:j inSection:i];
            CGSize itemSize = [_myDelegate collectionView:self.collectionView layout:self
                   sizeForItemWithWidth:itemWidth atIndexPath:itemIndexPath];
            
            // 10
            [section addItemToColumn:itemSize forIndex:j forColumn:columnIndex ];
        }
        // 11
        [_sectionData addObject:section];
        // 12
        _height += section.frame.size.height;
        currentOrigin.y = _height; }
}

- (CGSize)collectionViewContentSize {
    return CGSizeMake(self.collectionView.bounds.size.width,
                      _height);
}

- (UICollectionViewLayoutAttributes*) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    StackedGridLayoutSection *section =
    _sectionData[indexPath.section];
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes
                                                    layoutAttributesForCellWithIndexPath:indexPath];
    attributes.frame = [section frameForItemAtIndex:indexPath.item]; return attributes;
}

- (UICollectionViewLayoutAttributes *) layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    StackedGridLayoutSection *section =_sectionData[indexPath.section];
    UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes
                                                    layoutAttributesForSupplementaryViewOfKind:kind withIndexPath:indexPath];
    CGRect sectionFrame = section.frame; CGRect headerFrame =
        CGRectMake(0.0f,
               sectionFrame.origin.y - self.headerHeight,
               sectionFrame.size.width,
               self.headerHeight);
    attributes.frame = headerFrame;
    return attributes;
}

- (NSArray*)layoutAttributesForElementsInRect:(CGRect)rect { // 1
    NSMutableArray *attributes = [NSMutableArray new];
    // 2
    [_sectionData enumerateObjectsUsingBlock: ^(StackedGridLayoutSection *section,
                                                NSUInteger sectionIndex,
                                                BOOL *stop) {
        // 3
        CGRect sectionFrame = section.frame;
        CGRect headerFrame =
            CGRectMake(0.0f,
                   sectionFrame.origin.y - self.headerHeight,
                   sectionFrame.size.width, self.headerHeight);
        // 4
        if (CGRectIntersectsRect(headerFrame, rect)) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:sectionIndex];
            UICollectionViewLayoutAttributes *la = [self layoutAttributesForSupplementaryViewOfKind:
            UICollectionElementKindSectionHeader atIndexPath:indexPath];
            [attributes addObject:la];
        }
        // 5
        if (CGRectIntersectsRect(sectionFrame, rect)) { // 6
            for (NSInteger index = 0;
                 index < section.numberOfItems; index++)
            {
                // 7
                CGRect frame = [section frameForItemAtIndex:index];
                // 8
                if (CGRectIntersectsRect(frame, rect)) {
                    NSIndexPath *indexPath =[NSIndexPath indexPathForItem:index inSection:sectionIndex];
                    UICollectionViewLayoutAttributes *la = [self layoutAttributesForItemAtIndexPath:indexPath];
                    [attributes addObject:la];
                }
            }
        }
    }];
    // 9
    return attributes;
}
@end
