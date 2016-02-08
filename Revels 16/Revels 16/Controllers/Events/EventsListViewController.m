//
//  EventsListViewController.m
//  Revels 16
//
//  Created by Avikant Saini on 2/1/16.
//  Copyright © 2016 Dark Army. All rights reserved.
//

#import "EventsListViewController.h"
#import "EventsTableViewCell.h"
#import "REVEvent.h"

@interface EventsListViewController () <UISearchResultsUpdating, UISearchControllerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *extendedNavBarViewConstraint;

@end

@implementation EventsListViewController {
	NSMutableArray *events;
	NSMutableArray *filteredEvents;
	NSManagedObjectContext *managedObjectContext;
	NSFetchRequest *fetchRequest;
	NSInteger currentSegmentedIndex;
	
	UISwipeGestureRecognizer *leftSwipeGesture;
	UISwipeGestureRecognizer *rightSwipeGesture;
}

- (void)viewDidLoad {
	
    [super viewDidLoad];
	
	events = [NSMutableArray new];
	filteredEvents = [NSMutableArray new];
	
	self.selectedIndexPath = nil;
	currentSegmentedIndex = 0;
	
	managedObjectContext = [AppDelegate managedObjectContext];
	fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"REVEvent"];
	
	[self setupSearchController];
	
	[self.navigationController.navigationBar setTranslucent:NO];
	[self.navigationController.navigationBar setShadowImage:[UIImage imageNamed:@"TransparentPixel"]];
	[self.navigationController.navigationBar setBackgroundColor:GLOBAL_BACK_COLOR];
	[self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"Pixel"] forBarMetrics:UIBarMetricsDefault];
	
	leftSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
	[leftSwipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
	[self.view addGestureRecognizer:leftSwipeGesture];
	
	rightSwipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeGesture:)];
	[rightSwipeGesture setDirection:UISwipeGestureRecognizerDirectionRight];
	[self.view addGestureRecognizer:rightSwipeGesture];
	
}

- (void)viewDidAppear:(BOOL)animated {
	
	[self fetchLocalEvents];
	
	Reachability *reachability = [Reachability reachabilityForInternetConnection];
	if ([reachability isReachable])
		[self fetchEvents];
	
	if (self.guillotineMenuController) {
		// Uhh, hide the line?
	}
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)fetchEvents {
	
	SVHUD_SHOW;
	
    NSURL *eventsUrl = [NSURL URLWithString:@"http://api.mitportals.in"];
    
    ASMutableURLRequest *postRequest = [ASMutableURLRequest postRequestWithURL:eventsUrl];
    NSString *post = [NSString stringWithFormat:@"secret=%@", @"LUGbatchof2017"];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    [postRequest setHTTPBody:postData];
	
	[[[NSURLSession sharedSession] dataTaskWithRequest:postRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		if (error) {
			SVHUD_FAILURE(@"Error!");
			return;
		}
		
		PRINT_RESPONSE_HEADERS_AND_CODE;
		
		id jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//        NSLog(@"%@", jsonData);
		
		if (error == nil && statusCode == 200) {
			NSMutableArray *evnts = [REVEvent getEventsFromJSONData:[jsonData objectForKey:@"data"] storeIntoManagedObjectContext:managedObjectContext];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self fetchEventSchedule];
				events = [NSMutableArray arrayWithArray:evnts];
//				[self filterEventsForSelectedSegmentTitle:[self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex]];
			});
		}
		
//		SVHUD_HIDE;
		
	}] resume];
	
}

- (void)fetchEventSchedule {
	
	NSURL *eventsUrl = [NSURL URLWithString:@"http://schedule.mitportals.in"];
	
	ASMutableURLRequest *postRequest = [ASMutableURLRequest postRequestWithURL:eventsUrl];
	NSString *post = [NSString stringWithFormat:@"secret=%@", @"revels16Dastaan"];
	NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
	[postRequest setHTTPBody:postData];
	
	[[[NSURLSession sharedSession] dataTaskWithRequest:postRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		
		if (error) {
			// Fetch local data?
			SVHUD_FAILURE(@"Error!");
			return;
		}
		
		PRINT_RESPONSE_HEADERS_AND_CODE;
		
		id jsonData = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//		NSLog(@"%@", jsonData);
		
		if (error == nil && statusCode == 200) {
			NSMutableArray *evnts = [REVEvent eventsAfterUpdatingScheduleFromJSONData:[jsonData valueForKey:@"data"] inManagedObjectContext:managedObjectContext];
			dispatch_async(dispatch_get_main_queue(), ^{
				events = [NSMutableArray arrayWithArray:evnts];
				[self filterEventsForSelectedSegmentTitle:[self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex]];
			});
		}
		
		SVHUD_HIDE;
		
	}] resume];
	
}

- (void)fetchLocalEvents {
	NSError *error;
	events = [[managedObjectContext executeFetchRequest:fetchRequest error:&error] mutableCopy];
	if (error)
		NSLog(@"Error in fetching: %@", error.localizedDescription);
	[self filterEventsForSelectedSegmentTitle:[self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex]];
}

- (void)setupSearchController {
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.delegate = self;
	self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
	self.searchController.searchBar.delegate = self;
	self.searchController.searchBar.backgroundColor = [UIColor whiteColor];
	self.searchController.searchBar.tintColor = [UIColor blackColor];
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.definesPresentationContext = YES;
	self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (IBAction)segmentedControlValueChanged:(id)sender {
	
	self.selectedIndexPath = nil;
	
	UISegmentedControl *segmentedControl = (UISegmentedControl *)sender;
	NSInteger index = segmentedControl.selectedSegmentIndex;
	
	NSInteger direction = 1;
	if (index < currentSegmentedIndex)
		direction = -1;
	
	[UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.tableView.layer.transform = CATransform3DMakeTranslation(- direction * (SWdith + 40), 0, 0);
		self.tableView.alpha = 0.5;
	} completion:^(BOOL finished) {
		self.tableView.layer.transform = CATransform3DMakeTranslation(direction * (SWdith + 40), 0, 0);
		if (self.searchController.isActive && self.searchController.searchBar.text.length > 0)
			[self filterEventsForSearchString:self.searchController.searchBar.text andScopeBarTitle:[segmentedControl titleForSegmentAtIndex:index]];
		else
			[self filterEventsForSelectedSegmentTitle:[segmentedControl titleForSegmentAtIndex:index]];
		currentSegmentedIndex = index;
		[UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
			self.tableView.layer.transform = CATransform3DIdentity;
			self.tableView.alpha = 1.f;
		} completion:nil];
	}];
	
}

#pragma mark - Swipe gesture handler

- (void)handleSwipeGesture:(UISwipeGestureRecognizer *)recognizer {
	
	NSInteger direction = -1;
	NSInteger index = currentSegmentedIndex;
	NSInteger newIndex = (index == 0)?3:(index - 1);
	
	if (recognizer.direction == UISwipeGestureRecognizerDirectionRight) {
		direction = 1;
		newIndex = (index == 3)?0:(index + 1);
	}
	
	[UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.tableView.layer.transform = CATransform3DMakeTranslation(- direction * (SWdith + 40), 0, 0);
		self.tableView.alpha = 0.5;
	} completion:^(BOOL finished) {
		self.tableView.layer.transform = CATransform3DMakeTranslation(direction * (SWdith + 40), 0, 0);
		self.segmentedControl.selectedSegmentIndex = newIndex;
		if (self.searchController.isActive && self.searchController.searchBar.text.length > 0)
			[self filterEventsForSearchString:self.searchController.searchBar.text andScopeBarTitle:[self.segmentedControl titleForSegmentAtIndex:newIndex]];
		else
			[self filterEventsForSelectedSegmentTitle:[self.segmentedControl titleForSegmentAtIndex:newIndex]];
		currentSegmentedIndex = newIndex;
		[UIView animateWithDuration:0.15 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
			self.tableView.layer.transform = CATransform3DIdentity;
			self.tableView.alpha = 1.f;
		} completion:nil];
	}];
	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return filteredEvents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	REVEvent *event = [filteredEvents objectAtIndex:indexPath.row];
	
	EventsTableViewCell *cell;
 
	if ([indexPath compare:self.selectedIndexPath] == NSOrderedSame)
		cell = (EventsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"eventsCellExp" forIndexPath:indexPath];
	else
		cell = (EventsTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"eventsCell" forIndexPath:indexPath];
	
	if (cell == nil)
		cell = [[EventsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"eventsCell"];
	
	cell.eventNameLabel.text = event.name;
	cell.categoryNameLabel.text = event.categoryName;
	
	[cell.infoButton setTag:indexPath.row];
	[cell.infoButton addTarget:self action:@selector(infoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	if (event.isFavourite)
		[cell.favsButton setImage:[UIImage imageNamed:@"favsFilled"] forState:UIControlStateNormal];
	else
		[cell.favsButton setImage:[UIImage imageNamed:@"favsEmpty"] forState:UIControlStateNormal];
	
	[cell.favsButton setTag:indexPath.row];
	[cell.favsButton addTarget:self action:@selector(favsButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	cell.dateLabel.text = event.dateString;
	cell.timeLabel.text = event.timeString;
	cell.venueNameLabel.text = event.venue;
	cell.teamInformationLabel.text = [NSString stringWithFormat:@"Maximum team members: %@", event.maxTeamNo];
	cell.contactPersonLabel.text = event.contactName;
	
	[cell.timeButton setTag:indexPath.row];
	[cell.timeButton addTarget:self action:@selector(timeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	[cell.phoneButton setTag:indexPath.row];
	[cell.phoneButton addTarget:self action:@selector(phoneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	[tableView beginUpdates];
	
	if (![indexPath compare:self.selectedIndexPath] == NSOrderedSame)
		self.selectedIndexPath = indexPath;
	else
		self.selectedIndexPath = nil;
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	
	[tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([indexPath compare:self.selectedIndexPath] == NSOrderedSame)
		return 228.f;
	return 60.f;
}

#pragma mark - Cell button actions

- (void)infoButtonPressed:(id)sender {
//	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
	
//	REVEvent *event = [filteredEvents objectAtIndex:indexPath.row];
	
	// Show awesome alert...
}


- (void)favsButtonPressed:(id)sender {
	
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
	
	REVEvent *event = [filteredEvents objectAtIndex:indexPath.row];
	event.isFavourite = !event.isFavourite;
	
	NSError *error;
	if (![managedObjectContext save:&error])
		NSLog(@"Can't Save : %@, %@", error, [error localizedDescription]);
	
	[self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)timeButtonPressed:(id)sender {
	// Prompt adding an event
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
	NSLog(@"Time tapped for row: %li", indexPath.row);
}

- (void)phoneButtonPressed:(id)sender {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sender tag] inSection:0];
	NSLog(@"Phone tapped for row: %li", indexPath.row);
}

#pragma mark - Filtering

- (void)filterEventsForSelectedSegmentTitle:(NSString *)segmentTitle {
	filteredEvents = [NSMutableArray arrayWithArray:events];
	[filteredEvents filterUsingPredicate:[NSPredicate predicateWithFormat:@"day == %@", segmentTitle]];
	[self.tableView reloadData];
}

- (void)filterEventsForSearchString:(NSString *)searchString andScopeBarTitle:(NSString *)scopeTitle {
	filteredEvents = [NSMutableArray arrayWithArray:events];
	[filteredEvents filterUsingPredicate:[NSPredicate predicateWithFormat:@"name contains[cd] %@ AND day == %@", searchString, scopeTitle]];
	[self.tableView reloadData];
}

#pragma mark - Search controller results updating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
	UISearchBar *searchBar = searchController.searchBar;
	if (searchBar.text.length > 0) {
		if (searchBar.scopeButtonTitles.count > 0)
			[self filterEventsForSearchString:searchBar.text andScopeBarTitle:searchBar.scopeButtonTitles[searchBar.selectedScopeButtonIndex]];
		else
			[self filterEventsForSearchString:searchBar.text andScopeBarTitle:[self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex]];
	}
	else {
		[self filterEventsForSelectedSegmentTitle:[self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex]];
	}
}

#pragma mark - Search controller delegate

- (void)didPresentSearchController:(UISearchController *)searchController {
	[UIView animateWithDuration:0.3 animations:^{
		self.extendedNavBarViewConstraint.constant = 40.f;
	}];
	self.tableView.tableHeaderView = nil;
}

- (void)didDismissSearchController:(UISearchController *)searchController {
	[UIView animateWithDuration:0.3 animations:^{
		self.extendedNavBarViewConstraint.constant = 0.f;
	}];
	self.tableView.tableHeaderView = self.searchController.searchBar;
}

#pragma mark - Search bar delegate

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope {
	if (searchBar.text.length > 0)
		[self filterEventsForSearchString:searchBar.text andScopeBarTitle:searchBar.scopeButtonTitles[searchBar.selectedScopeButtonIndex]];
	else
		[self searchBarCancelButtonClicked:searchBar];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	[self filterEventsForSelectedSegmentTitle:[self.segmentedControl titleForSegmentAtIndex:self.segmentedControl.selectedSegmentIndex]];
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
