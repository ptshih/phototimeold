//
//  SearchTermController.m
//  Moogle
//
//  Created by Peter Shih on 7/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SearchTermController.h"
#import "PSSearchCenter.h"

@implementation SearchTermController

@synthesize delegate = _delegate;

- (void)loadView {
  [super loadView];
  
  [self setupTableViewWithFrame:self.view.bounds andStyle:UITableViewStylePlain andSeparatorStyle:UITableViewCellSeparatorStyleSingleLine];
}

#pragma mark - Setup
- (void)setupTableFooter {
  // subclass should implement
  UIImageView *footerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-table-footer.png"]];
  _tableView.tableFooterView = footerImage;
  [footerImage release];
}

#pragma mark - Search
- (void)searchWithTerm:(NSString *)term {
  [self.items removeAllObjects];
  
  NSArray *filteredArray = [[PSSearchCenter defaultCenter] searchResultsForTerm:term];

  if ([filteredArray count] > 0) {
    [self.items addObject:filteredArray];
  }
  [self.tableView reloadData];
}

#pragma mark - Table
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  
  UIView *sectionHeaderView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 26)] autorelease];
//  sectionHeaderView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-table-header.png"]];
  sectionHeaderView.backgroundColor = SECTION_HEADER_COLOR;
  
  UILabel *sectionHeaderLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 310, 24)] autorelease];
  sectionHeaderLabel.backgroundColor = [UIColor clearColor];
  sectionHeaderLabel.text = @"Previously Searched...";
  sectionHeaderLabel.textColor = [UIColor whiteColor];
  sectionHeaderLabel.shadowColor = [UIColor blackColor];
  sectionHeaderLabel.shadowOffset = CGSizeMake(0, 1);
  sectionHeaderLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:12.0];
  [sectionHeaderView addSubview:sectionHeaderLabel];
  
  return sectionHeaderView;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (tableView.style == UITableViewStylePlain) {
    UIView *backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    backgroundView.backgroundColor = LIGHT_GRAY;
    cell.backgroundView = backgroundView;
    
    UIView *selectedBackgroundView = [[UIView alloc] initWithFrame:cell.bounds];
    selectedBackgroundView.backgroundColor = CELL_SELECTED_COLOR;
    cell.selectedBackgroundView = selectedBackgroundView;
    
    [backgroundView release];
    [selectedBackgroundView release];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = nil;
  NSString *reuseIdentifier = @"searchTermCell";
  
  cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
  }
  
  NSString *term = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  cell.textLabel.text = term;
  
  return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
  
  NSString *term = [[self.items objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
  
  // Search term selected
  if (self.delegate && [self.delegate respondsToSelector:@selector(searchTermSelected:)]) {
    [self.delegate searchTermSelected:term];
  }
}

@end
