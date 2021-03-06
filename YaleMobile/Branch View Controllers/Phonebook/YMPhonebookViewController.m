//
//  YMPhonebookViewController.m
//  YaleMobile
//
//  Created by Danqing on 2/2/13.
//  Copyright (c) 2013 Danqing Liu. All rights reserved.
//

#import "YMPhonebookViewController.h"
#import "YMGlobalHelper.h"
#import "YMSubtitleCell.h"
#import "YMDatabaseHelper.h"
#import "YMTheme.h"
#import "Office+Initialize.h"
#import "YMServerCommunicator.h"
#import <PureLayout/PureLayout.h>

@interface YMPhonebookViewController ()

@end

@implementation YMPhonebookViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  [YMGlobalHelper addMenuButtonToController:self];
  self.tableView.sectionIndexColor = [[YMTheme blue] colorWithAlphaComponent:0.7];
  
  if ([self.tableView respondsToSelector:@selector(setSectionIndexColor:)]) {
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.sectionIndexTrackingBackgroundColor = [UIColor clearColor];
  }
  
  self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
  self.tableView.separatorInset = UIEdgeInsetsZero;
  self.tableView.separatorColor = [YMTheme separatorGray];

  CGRect rect = self.searchBar.frame;
  UIView *topLineView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, rect.size.width, 1)];
  UIView *bottomLineView = [[UIView alloc]initWithFrame:CGRectMake(0, rect.size.height - 1, rect.size.width, 1)];
  topLineView.backgroundColor = [YMTheme separatorGray];
  bottomLineView.backgroundColor = [YMTheme separatorGray];
  [self.searchBar addSubview:topLineView];
  [self.searchBar addSubview:bottomLineView];

  [self.navigationController.navigationBar setBarTintColor:[YMTheme blue]];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  [YMServerCommunicator cancelAllHTTPRequests];
  
  self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;

  [YMGlobalHelper setupSlidingViewControllerForController:self];
  
  if ((self.database = [YMDatabaseHelper getManagedDocument]))
    [self loadData];
  else {
    [YMDatabaseHelper openDatabase:@"database" usingBlock:^(UIManagedDocument *document) {
      self.database = document;
      [YMDatabaseHelper setManagedDocumentTo:document];
      [self loadData];
    }];
  }
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}


- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)loadData
{
  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Office"];
  request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
  self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.database.managedObjectContext sectionNameKeyPath:@"firstLetter" cacheName:nil];
  [self performFetch];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}

- (void)menu:(id)sender
{
  [YMGlobalHelper setupMenuButtonForController:self];
}

- (NSFetchedResultsController *)newFetchedResultsControllerWithSearch:(NSString *)searchString
{
  NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Office"];
  NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
  NSPredicate *filterPredicate = nil;
  
  NSMutableArray *predicateArray = [NSMutableArray array];
  if(searchString.length) {
    [predicateArray addObject:[NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@", searchString]];
    filterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];
  }
  [request setPredicate:filterPredicate];
  [request setSortDescriptors:sortDescriptors];
  
  // Edit the section name key path and cache name if appropriate.
  // nil for section name key path means "no sections".
  NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                             managedObjectContext:self.database.managedObjectContext
                                                                                               sectionNameKeyPath:nil
                                                                                                        cacheName:nil];
  fetchedResultsController.delegate = self;
  
  NSError *error = nil;
  if (![fetchedResultsController performFetch:&error])
  {
    /*
     Replace this implementation with code to handle the error appropriately.
     
     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
     */
    DLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
  
  return fetchedResultsController;
}

- (NSFetchedResultsController *)fetchedResultsControllerForTableView:(UITableView *)tableView
{
  return tableView == self.tableView ? self.fetchedResultsController : self.searchResultsController;
}

- (void)fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
  Office *office = [fetchedResultsController objectAtIndexPath:indexPath];
  ((YMSubtitleCell *)cell).primary1.text = office.name;
  ((YMSubtitleCell *)cell).secondary1.text = [@"(203)-" stringByAppendingString:office.phone];
  
  /* deprecated
   CGSize textSize = [office.name sizeWithFont:[UIFont fontWithName:@"HelveticaNeue" size:16] constrainedToSize:CGSizeMake(272, 1000)];
   */
  CGSize textSize = [YMGlobalHelper boundText:office.name withFont:[UIFont fontWithName:@"HelveticaNeue" size:16] andConstraintSize:CGSizeMake(272, 1000)];
  CGRect frame = ((YMSubtitleCell *)cell).primary1.frame;
  frame.size.height = textSize.height;
  ((YMSubtitleCell *)cell).primary1.frame = frame;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
  UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
  [tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
  UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
  
  switch(type)
  {
    case NSFetchedResultsChangeInsert:
      [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
      break;
    case NSFetchedResultsChangeDelete:
      [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
      break;
      
    case NSFetchedResultsChangeMove:
    case NSFetchedResultsChangeUpdate:
    default:
      break;
  }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
  UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
  
  switch(type)
  {
    case NSFetchedResultsChangeInsert:
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    case NSFetchedResultsChangeDelete:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
    case NSFetchedResultsChangeUpdate:
      [self fetchedResultsController:controller configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
      break;
    case NSFetchedResultsChangeMove:
      [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
      [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
      break;
  }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
  UITableView *tableView = controller == self.fetchedResultsController ? self.tableView : self.searchDisplayController.searchResultsTableView;
  [tableView endUpdates];
}

- (void)createActionSheetWithNumber:(NSString *)number
{
  UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Do you want to call this number?"] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:[NSString stringWithFormat:@"Call %@", number], @"Copy to Clipboard", nil];
  actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:@"Copy to Clipboard"]) {
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:self.phoneNumber];
  } else if (buttonIndex != [actionSheet cancelButtonIndex])
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel://" stringByAppendingString:self.phoneNumber]]];
}

#pragma mark - Search Bar

- (void)filterContentForSearchText:(NSString*)searchText scope:(NSInteger)scope
{
  self.searchResultsController = [self newFetchedResultsControllerWithSearch:self.searchDisplayController.searchBar.text];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willUnloadSearchResultsTableView:(UITableView *)tableView;
{
  self.searchResultsController.delegate = nil;
  self.searchResultsController = nil;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
  [self filterContentForSearchText:searchString scope:0];
  return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return [[[self fetchedResultsControllerForTableView:tableView] sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger numberOfRows = 0;
  
  NSFetchedResultsController *fetchController = [self fetchedResultsControllerForTableView:tableView];
  NSArray *sections = fetchController.sections;
  if(sections.count > 0) {
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];
    numberOfRows = [sectionInfo numberOfObjects];
  }
  
  return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  YMSubtitleCell *cell = (YMSubtitleCell *)[tableView dequeueReusableCellWithIdentifier:@"Phonebook Cell"];
  if (cell == nil) {
    NSArray *topLevelObjects = [[NSBundle mainBundle] loadNibNamed:@"Phonebook Cell" owner:self options:nil];
    cell = [topLevelObjects objectAtIndex:0];
  }
  
  [self fetchedResultsController:[self fetchedResultsControllerForTableView:tableView] configureCell:cell atIndexPath:indexPath];
  
  cell.primary1.textColor              = [YMTheme gray];
  cell.primary1.highlightedTextColor   = cell.primary1.textColor;
  cell.secondary1.textColor            = [YMTheme lightGray];
  cell.secondary1.highlightedTextColor = cell.secondary1.textColor;
  
  [YMGlobalHelper setupHighlightBackgroundViewWithColor:[YMTheme cellHighlightBackgroundViewColor]
                                                forCell:cell];
  
  return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  Office *office = [[self fetchedResultsControllerForTableView:tableView] objectAtIndexPath:indexPath];

  CGSize textSize = [YMGlobalHelper boundText:office.name withFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:16] andConstraintSize:CGSizeMake(272, 1000)];
  
  return textSize.height + 39;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
  return 26;
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
  /* bad return, but kept for reference
  if (self.searchDisplayController.active) return nil;
   */
  if (self.searchDisplayController.active) return -1;
  
  if([title isEqualToString:UITableViewIndexSearch]){
    [tableView setContentOffset:CGPointMake(0.0, -tableView.contentInset.top)];
    return NSNotFound;
  } else {
    return index - 1;
  }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
  if (self.searchDisplayController.active) return nil;
  
  NSArray *array = [[NSArray alloc] initWithObjects:UITableViewIndexSearch, nil];
  array = [array arrayByAddingObjectsFromArray:[self.fetchedResultsController sectionIndexTitles]];
  return array;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	UIView* headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 26.0)];
	
	UILabel * headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
  
  headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.textColor = [UIColor grayColor];
	headerLabel.font = [UIFont boldSystemFontOfSize:14];
	headerLabel.frame = CGRectMake(17.0, 1.0, 300.0, 23.0);
  
  if (self.searchDisplayController.active) {
    NSInteger count = [[[self fetchedResultsControllerForTableView:tableView].sections objectAtIndex:0] numberOfObjects];
    if (count == 0)
      headerLabel.text = @"No entries found";
    else if (count == 1)
      headerLabel.text = @"Found 1 entry";
    else
      headerLabel.text = [NSString stringWithFormat:@"Found %ld entries", (long)count];
  }
  else headerLabel.text = [[self.fetchedResultsController sectionIndexTitles] objectAtIndex:section];
	
  [headerView addSubview:headerLabel];
  headerView.backgroundColor = [[YMTheme separatorGray] colorWithAlphaComponent:0.6];
  
  UIView *hairlineBorderView = [UIView newAutoLayoutView];
  [headerView addSubview:hairlineBorderView];
  hairlineBorderView.backgroundColor = [YMTheme separatorGray];
  [hairlineBorderView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
  [hairlineBorderView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
  [hairlineBorderView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:headerView];
  [hairlineBorderView autoSetDimension:ALDimensionHeight toSize:0.5];
  
  UIView *topBorderView = [UIView newAutoLayoutView];
  [headerView addSubview:topBorderView];
  topBorderView.backgroundColor = [YMTheme separatorGray];
  [topBorderView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:0];
  [topBorderView autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
  [topBorderView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:headerView];
  [topBorderView autoSetDimension:ALDimensionHeight toSize:0.5];
  
	return headerView;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  YMSubtitleCell *cell = (YMSubtitleCell *)[tableView cellForRowAtIndexPath:indexPath];
  self.phoneNumber = cell.secondary1.text;
  [self createActionSheetWithNumber:cell.secondary1.text];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
