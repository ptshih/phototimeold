//
//  AlbumViewController.m
//  PhotoTime
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 Seven Minute Labs. All rights reserved.
//

#import "AlbumViewController.h"
#import "AlbumDataCenter.h"
#import "PhotoViewController.h"
#import "FilterViewController.h"
#import "AlbumCell.h"
#import "Album.h"

@implementation AlbumViewController

@synthesize albumType = _albumType;

- (id)init {
  self = [super init];
  if (self) {
    _albumType = [[NSUserDefaults standardUserDefaults] integerForKey:@"lastAlbumType"];
    _fetchLimit = 25;
    _fetchTotal = _fetchLimit;
    _frcDelegate = nil;
//    _sectionNameKeyPathForFetchedResultsController = [@"daysAgo" retain];
  }
  return self;
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCardController) name:kReloadAlbumController object:nil];
  [self reloadCardController];
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:kReloadAlbumController object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"logoutRequested"]) {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
      [[NSNotificationCenter defaultCenter] postNotificationName:kLogoutRequested object:nil];
    }];
  }
}

- (void)loadView {
  [super loadView];
  
  [self resetFetchedResultsController];
  
  // Table
  CGRect tableFrame = self.view.bounds;
  [self setupTableViewWithFrame:tableFrame andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleNone];
  
//  self.tableView.rowHeight = 120.0;
  
  if (self.albumType == AlbumTypeSearch) {
    [self addBackButton];
    
    self.navigationItem.rightBarButtonItem = [UIBarButtonItem navButtonWithTitle:@"Save" withTarget:self action:@selector(save) buttonType:NavButtonTypeBlue];
  }

  
//  UILabel *searchLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.width, self.view.height - 44.0 - (isDeviceIPad() ? 352 : 216))] autorelease];
//  searchLabel.numberOfLines = 8;
//  searchLabel.text = @"Search for keywords, people, or places.\n\nTypeahead table view here";
//  searchLabel.textAlignment = UITextAlignmentCenter;
//  searchLabel.textColor = [UIColor whiteColor];
//  searchLabel.shadowColor = [UIColor blackColor];
//  searchLabel.shadowOffset = CGSizeMake(0, 1);
//  searchLabel.backgroundColor = [UIColor clearColor];
  

//  _searchTermController.view.height -= 44;
//  _searchTermController.view.frame = CGRectMake(0, 0, self.view.width, self.view.height - (isDeviceIPad() ? 352 : 216) - 44);

  
//  [self addButtonWithTitle:@"Logout" andSelector:@selector(logout) isLeft:YES];
//  [self addButtonWithImage:[UIImage imageNamed:@"bg_searchbar_textfield.png"] withTarget:self action:@selector(search) isLeft:YES];
  
  //  self.navigationItem.leftBarButtonItem = [self navButtonWithImage:[UIImage imageNamed:@"icon_gear.png"] withTarget:self action:@selector(logout) buttonType:NavButtonTypeNormal];
  

  
//  _navTitleLabel.text = @"PhotoTime";
  
  // Pull Refresh
//  [self setupPullRefresh];
  
//  [self setupLoadMoreView];
  
  [self executeFetch:FetchTypeCold];
}

- (void)save {
  
}

- (void)updateState {
  [super updateState];
  
  // Update Nav Title
  switch (self.albumType) {
    case AlbumTypeMe:
      _navTitleLabel.text = @"Your Albums";
      break;
    case AlbumTypeFriends:
      _navTitleLabel.text = @"Your Friends";
      break;
    case AlbumTypeMobile:
      _navTitleLabel.text = @"Mobile Uploads";
      break;
    case AlbumTypeProfile:
      _navTitleLabel.text = @"Profile Pictures";
      break;
    case AlbumTypeWall:
      _navTitleLabel.text = @"Wall Photos";
      break;
    case AlbumTypeFavorites:
      _navTitleLabel.text = @"Favorites";
      break;
    case AlbumTypeSearch:
      _navTitleLabel.text = @"Search Results";
    default:
      break;
  }
}

- (void)reloadCardController {
  [super reloadCardController];
  _hasMore = YES;
  _fetchTotal = _fetchLimit;
  if ([[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"]) {
    [self dataSourceDidLoad];
  }
}

- (void)unloadCardController {
  [super unloadCardController];
}

#pragma mark - TableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  // Preload all album covers
  NSString *urlPath = album.coverPhoto;
  if (urlPath) {
    [[PSImageCache sharedCache] cacheImageForURLPath:urlPath withDelegate:nil];
  }
  
  if (isDeviceIPad()) {
    return 288.0;
  } else {
    return 120.0;
  }
}

- (void)tableView:(UITableView *)tableView configureCell:(id)cell atIndexPath:(NSIndexPath *)indexPath {
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  
  [cell fillCellWithObject:album];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  Album *album = [self.fetchedResultsController objectAtIndexPath:indexPath];
  album.lastViewed = [NSDate date];
  [PSCoreDataStack saveInContext:[album managedObjectContext]];
  
  PhotoViewController *pvc = [[PhotoViewController alloc] init];
  pvc.album = album;
  
  // If this album is WALL, sort by timestamp instead
  if (self.albumType == AlbumTypeWall) {
    pvc.sortKey = @"timestamp";
  }
  
//  [self.navigationController pushViewController:pvc animated:YES];
  [[PSExposeController sharedController] pushViewController:pvc animated:YES];
  [pvc release];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  AlbumCell *cell = nil;
  NSString *reuseIdentifier = [AlbumCell reuseIdentifier];
  
  cell = (AlbumCell *)[tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if(cell == nil) { 
    cell = [[[AlbumCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  [self tableView:tableView configureCell:cell atIndexPath:indexPath];
  
  return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
  [(AlbumCell *)cell loadPhoto];
}

#pragma mark -
#pragma mark FetchRequest
- (NSFetchRequest *)getFetchRequest {
  NSArray *sortDescriptors = nil;
  NSString *fetchTemplate = nil;
  NSDictionary *substitutionVariables = nil;
  NSString *facebookId = [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"] ? [[NSUserDefaults standardUserDefaults] stringForKey:@"facebookId"] : @"";
  
  switch (self.albumType) {
    case AlbumTypeMe:
      fetchTemplate = FETCH_ME;
      substitutionVariables = [NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeFriends:
      fetchTemplate = FETCH_FRIENDS;
      substitutionVariables = [NSDictionary dictionaryWithObject:facebookId forKey:@"desiredFromId"];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeMobile:
      fetchTemplate = FETCH_MOBILE;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeWall:
      fetchTemplate = FETCH_WALL;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeProfile:
      fetchTemplate = FETCH_PROFILE;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeFavorites:
      fetchTemplate = FETCH_FAVORITES;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    case AlbumTypeSearch:
      fetchTemplate = FETCH_SEARCH;
      substitutionVariables = [NSDictionary dictionary];
      sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]];
      break;
    default:
      break;
  }
  
  NSFetchRequest *fetchRequest = [[PSCoreDataStack managedObjectModel] fetchRequestFromTemplateWithName:fetchTemplate substitutionVariables:substitutionVariables];
  [fetchRequest setSortDescriptors:sortDescriptors];
  [fetchRequest setFetchBatchSize:10];
  [fetchRequest setFetchLimit:_fetchTotal];
  return fetchRequest;
}

- (void)dealloc {
  [super dealloc];
}

@end