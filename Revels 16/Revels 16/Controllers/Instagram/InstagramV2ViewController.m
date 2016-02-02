//
//  InstagramV2ViewController.m
//  Revels 16
//
//  Created by Avikant Saini on 2/2/16.
//  Copyright © 2016 Dark Army. All rights reserved.
//

#import "InstagramV2ViewController.h"
#import "ParallaxCollectionViewCell.h"
#import "InstagramData.h"
#import "InstagramDetailViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "DMSlideTransition.h"

@interface InstagramV2ViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@end

@implementation InstagramV2ViewController {
	NSMutableArray *instagramObjects;
	NSURL *nextURL;
	DMSlideTransition *slideTransistion;
}

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
	instagramObjects = [NSMutableArray new];
	
	SVHUD_SHOW;
	
	NSString *URLString = [NSString stringWithFormat:@"https://api.instagram.com/v1/tags/%@/media/recent?client_id=fd6b3100174e42d7aa7d546574e01c76", kTagToSearch];
	
	nextURL = [NSURL URLWithString:URLString];
	
	[self fetchImages];
	
}

- (void)fetchImages {
	
	ASMutableURLRequest *request = [ASMutableURLRequest getRequestWithURL:nextURL];
	
	[[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		if (error) {
			SVHUD_FAILURE(@"Error!");
			return;
		}
		
		PRINT_RESPONSE_HEADERS_AND_CODE;
		
		id jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
		
		if (statusCode == 200) {
			
			if ([jsonData valueForKeyPath:@"pagination.next_url"])
				nextURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", [jsonData valueForKeyPath:@"pagination.next_url"]]];
			
			id imagesJSON = [jsonData valueForKey:@"data"];
			NSArray *imagesArray = [InstagramData getArrayFromJSONData:imagesJSON];
			
			[instagramObjects addObjectsFromArray:imagesArray];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self.collectionView reloadData];
				[self.collectionView reloadInputViews];
				SVHUD_HIDE;
			});
			
		}
		
	}] resume];
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Collection view data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return instagramObjects.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	ParallaxCollectionViewCell *cell = (ParallaxCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"instaCell" forIndexPath:indexPath];
	
	if (cell == nil)
		cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"instaCell" forIndexPath:indexPath];
	
	InstagramData *instaData = [instagramObjects objectAtIndex:indexPath.row];
	
	cell.imageURL = instaData.lowResURL;
	cell.placeholderImage = [UIImage imageNamed:@"RevelsLogo"];
	
	cell.tagsLabel.text = instaData.tags;
	cell.likesCountLabel.text = [NSString stringWithFormat:@"%li", instaData.likesCount];
	cell.commentsCountLabel.text = [NSString stringWithFormat:@"%li", instaData.commentsCount];
	
	return cell;
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	
	InstagramData *instaData = [instagramObjects objectAtIndex:indexPath.row];
	
	InstagramDetailViewController *idvc = [self.storyboard instantiateViewControllerWithIdentifier:@"InstagramDetailVC"];
	idvc.instaData = instaData;
	
	if (!slideTransistion)
		slideTransistion = [[DMSlideTransition alloc] init];
	[slideTransistion setBackgroundColor:[UIColor blackColor]];
	
	[idvc setTransitioningDelegate:slideTransistion];

	[self.navigationController presentViewController:idvc animated:YES completion:nil];
}

#pragma mark - Collection view delegate flow layout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	CGFloat size = self.collectionView.bounds.size.width/2 - 16;
	return CGSizeMake(size, size);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
	return UIEdgeInsetsMake(4, 4, 4, 4);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 16.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 16.f;
}

#pragma mark - Scroll view delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if (scrollView == self.collectionView) {
		NSArray *visibleCells = self.collectionView.visibleCells;
		for (ParallaxCollectionViewCell *cell in visibleCells) {
			CGFloat yOffset = ((self.collectionView.contentOffset.y - cell.frame.origin.y) / IMAGE_HEIGHT) * IMAGE_OFFSET_SPEED;
			cell.imageOffset = CGPointMake(0.0f, yOffset);
		}
		ParallaxCollectionViewCell *lastCell = [visibleCells lastObject];
		NSIndexPath *lastIndexPath = [self.collectionView indexPathForCell:lastCell];
		if (lastIndexPath.row > instagramObjects.count - 4)
			[self fetchImages];
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end