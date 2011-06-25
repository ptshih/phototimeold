
//
//  AlbumDataCenter.m
//  Photomunk
//
//  Created by Peter Shih on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AlbumDataCenter.h"
#import "Album.h"
#import "Album+Serialize.h"

static dispatch_queue_t _coreDataSerializationQueue = nil;

@implementation AlbumDataCenter

+ (void)initialize {
  _coreDataSerializationQueue = dispatch_queue_create("com.sevenminutelabs.albumCoreDataSerializationQueue", NULL);
}

+ (AlbumDataCenter *)defaultCenter {
  static AlbumDataCenter *defaultCenter = nil;
  if (!defaultCenter) {
    defaultCenter = [[self alloc] init];
  }
  return defaultCenter;
}

- (id)init {
  self = [super init];
  if (self) {
    _parseIndex = 0;
    _totalAlbumsToParse = 0;
    _pendingRequestsToParse = 0;
    _pendingResponses = [[NSMutableArray alloc] initWithCapacity:1];
  }
  return self;
}

#pragma mark -
#pragma mark Prepare Request
- (void)getAlbums {
  //  curl -F "batch=[ {'method': 'GET', 'name' : 'get-friends', 'relative_url': 'me/friends', 'omit_response_on_success' : true}, {'method': 'GET', 'name' : 'get-albums', 'depends_on':'get-friends', 'relative_url': 'albums?ids=me,{result=get-friends:$.data..id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=100', 'omit_response_on_success' : false} ]" https://graph.facebook.com
  
  /*
   curl -F "access_token=D1LgK2fmX11PjBMtys6iI68Kei67r5jPCuB24sf1IrM.eyJpdiI6InFjQ0FPbHVQRDl0b3hzMGZZVWFiSGcifQ.jKiEolLuK1lIgKOnC7Q5_iYWrv-4VEKD-X-zREhyn7r8h2ROyuOJ8yDWn5usdvcbDjkerlvTYVX5A1q3KEKPDSABn0i3nK9pC5KmX9S0clAoV6yv8AGvrBy6NXRleCoJ" -F "batch=[ {'method': 'GET', 'name' : 'get-friends', 'relative_url': 'me/friends?fields=id,name', 'omit_response_on_success' : true}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[0:199:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[200:399:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[400:599:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[600:799:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[800:999:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false}, {'method': 'GET', 'depends_on':'get-friends', 'relative_url': 'albums?ids={result=get-friends:$.data[1000:1199:1].id}&fields=id,from,name,description,type,created_time,updated_time,cover_photo,count&limit=0', 'omit_response_on_success' : false} ]"
   */
  
  /*
   Multiqueries FQL
   https://api.facebook.com/method/fql.multiquery?format=json&queries=
   
   {"query1":"SELECT uid2 FROM friend WHERE uid1 = me()", "query2":"SELECT aid,owner,cover_pid,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner IN (SELECT uid2 FROM #query1)"}
   
   */
  
  
  /*
   {'query1':'SELECT aid,owner,cover_pid,name FROM album WHERE owner = me()','query2':'SELECT src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)'}
   */
  
  
  // This is retarded... if the user has more than batchSize friends, we'll just fire off multiple requests
  NSURL *albumsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.multiquery"]];
  
  // Apply since if exists
  NSDate *sinceDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"albums.since"];
  NSTimeInterval since = [sinceDate timeIntervalSince1970] - SINCE_SAFETY_NET;
    
  // Get batch size/count
  NSArray *friends = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"facebookFriends"] allKeys];
  NSInteger batchSize = 150;
  NSInteger batchCount = ceil((CGFloat)[friends count] / (CGFloat)batchSize);
  NSRange range;
  
  // ME
  NSMutableDictionary *queries = [NSMutableDictionary dictionary];
  NSMutableDictionary *params = [NSMutableDictionary dictionary];
  [params setValue:@"json" forKey:@"format"];
  [queries setValue:[NSString stringWithFormat:@"SELECT aid,object_id,cover_pid,owner,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner = me() AND modified_major > %0.0f", since] forKey:@"query1"];
  [queries setValue:[NSString stringWithFormat:@"SELECT aid,src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)"] forKey:@"query2"];

  [params setValue:[queries JSONRepresentation] forKey:@"queries"];
  
  _pendingRequestsToParse++;
  [self sendRequestWithURL:albumsUrl andMethod:POST andHeaders:nil andParams:params andUserInfo:nil];
  
  // FRIENDS
  for (int i=0; i<batchCount; i++) {
    NSMutableDictionary *friendQueries = [NSMutableDictionary dictionary];
    NSMutableDictionary *friendParams = [NSMutableDictionary dictionary];
    [friendParams setValue:@"json" forKey:@"format"];
    
    NSInteger remainingFriends = [friends count] - (i * batchSize);
    NSInteger length = (batchSize > remainingFriends) ? remainingFriends : batchSize;
    range = NSMakeRange(i * batchSize, length);
    NSArray *batchFriends = [friends subarrayWithRange:range];
    
    [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,object_id,owner,cover_pid,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner IN (%@) AND modified_major > %0.0f", [batchFriends componentsJoinedByString:@","], since] forKey:@"query1"];
    [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)"] forKey:@"query2"];
    
    [friendParams setValue:[friendQueries JSONRepresentation] forKey:@"queries"];
    
    _pendingRequestsToParse++;
    [self sendRequestWithURL:albumsUrl andMethod:POST andHeaders:nil andParams:friendParams andUserInfo:nil];
  }
}

- (void)getAlbumsForFriendIds:(NSArray *)friendIds {
  NSURL *albumsUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.facebook.com/method/fql.multiquery"]];
  
  NSMutableDictionary *friendQueries = [NSMutableDictionary dictionary];
  NSMutableDictionary *friendParams = [NSMutableDictionary dictionary];
  [friendParams setValue:@"json" forKey:@"format"];
  
  [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,object_id,owner,cover_pid,name,description,location,size,type,modified_major,created,modified,can_upload FROM album WHERE owner IN (%@)", [friendIds componentsJoinedByString:@","]] forKey:@"query1"];
  [friendQueries setValue:[NSString stringWithFormat:@"SELECT aid,src_big FROM photo WHERE pid IN (SELECT cover_pid FROM #query1)"] forKey:@"query2"];
  
  [friendParams setValue:[friendQueries JSONRepresentation] forKey:@"queries"];
  
  _pendingRequestsToParse++;
  [self sendRequestWithURL:albumsUrl andMethod:POST andHeaders:nil andParams:friendParams andUserInfo:nil];
}

#pragma mark -
#pragma mark Serialization

#pragma mark Core Data Serialization
- (void)serializeAlbumsWithArray:(NSArray *)array inContext:(NSManagedObjectContext *)context {
  NSString *uniqueKey = @"aid";
  NSString *entityName = @"Album";
  
  // Special multiquery treatment
  NSArray *albumArray = nil;
  NSArray *coverArray = nil;
  for (NSDictionary *fqlResult in array) {
    if ([[fqlResult valueForKey:@"name"] isEqualToString:@"query1"]) {
      albumArray = [fqlResult valueForKey:@"fql_result_set"];
    } else if ([[fqlResult valueForKey:@"name"] isEqualToString:@"query2"]) {
      coverArray = [fqlResult valueForKey:@"fql_result_set"];
    } else {
      // error, invalid result
#warning facebook response invalid, alert error
      return;
    }
  }
  
  // Number of albums in this array
//  NSInteger resultCount = [albumArray count];

  // Create a dictionary of all new covers
  NSMutableDictionary *covers = [NSMutableDictionary dictionary];
  for (NSDictionary *cover in coverArray) {
    [covers setObject:[cover objectForKey:@"src_big"] forKey:[cover objectForKey:uniqueKey]];
  }
  
  // Find all existing Entities
  NSArray *newUniqueKeyArray = [albumArray valueForKey:uniqueKey];
  NSFetchRequest *existingFetchRequest = [[[NSFetchRequest alloc] init] autorelease];
  [existingFetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
  [existingFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(%K IN %@)", uniqueKey, newUniqueKeyArray]];
  [existingFetchRequest setPropertiesToFetch:[NSArray arrayWithObject:uniqueKey]];
  
  NSError *error = nil;
  NSArray *foundEntities = [context executeFetchRequest:existingFetchRequest error:&error];
  
  // Create a dictionary of existing entities
  NSMutableDictionary *existingEntities = [NSMutableDictionary dictionary];
  for (id foundEntity in foundEntities) {
    [existingEntities setObject:foundEntity forKey:[foundEntity valueForKey:uniqueKey]];
  }
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  int i = 0;
  Album *existingEntity = nil;
  for (NSDictionary *newEntity in albumArray) {
    NSString *key = [newEntity objectForKey:uniqueKey];
    NSString *coverSrcBig = [covers objectForKey:key];
    existingEntity = [existingEntities objectForKey:key];
    if (existingEntity) {
      // update
      [existingEntity updateAlbumWithDictionary:newEntity andCover:coverSrcBig];
    } else {
      // insert
      [Album addAlbumWithDictionary:newEntity andCover:coverSrcBig inContext:context];
    }
    i++;
    _parseIndex++;
    
    if (_parseIndex % 100 == 0) {
      NSNumber *progress = [NSNumber numberWithFloat:((CGFloat)_parseIndex / (CGFloat)_totalAlbumsToParse)];
      [[NSNotificationCenter defaultCenter] postNotificationName:kUpdateLoginProgress object:nil userInfo:[NSDictionary dictionaryWithObject:progress forKey:@"progress"]];
      NSLog(@"update progress index: %d, total: %d, percent: %@", _parseIndex, _totalAlbumsToParse, progress);
    }
    
    // Perform batch core data saves
    if (_parseIndex % 1000 == 0) {
      [PSCoreDataStack saveInContext:context];
      [PSCoreDataStack resetInContext:context];
      
      [pool drain];
      pool = [[NSAutoreleasePool alloc] init];
    }
  }
  
  [pool drain];
}

- (void)parsePendingResponses {
  // Process the batched results using GCD  
  dispatch_async(_coreDataSerializationQueue, ^{
    
    NSManagedObjectContext *context = [PSCoreDataStack newManagedObjectContext];
    
    for (NSArray *response in _pendingResponses) {
      [self serializeAlbumsWithArray:response inContext:context];
    }
    [_pendingResponses removeAllObjects];
    
    // Save the context
    [PSCoreDataStack saveInContext:context];
    
    // Release context
    [context release];
    
    dispatch_async(dispatch_get_main_queue(), ^{
      // reset counters
      _parseIndex = 0;
      _totalAlbumsToParse = 0;
      
      // Inform Delegate if all responses are parsed
      if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFinish:withResponse:)]) {
        [_delegate performSelector:@selector(dataCenterDidFinish:withResponse:) withObject:nil withObject:nil];
        [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"albums.since"];
      }
    });
  });
}

#pragma mark -
#pragma mark PSDataCenterDelegate
- (void)dataCenterRequestFinished:(ASIHTTPRequest *)request {
  // Put the responses into a parse pending array
  id response = [[request responseData] JSONValue];
  
  // Lets tally up all the counts
  // Special multiquery treatment
  NSArray *albumArray = nil;
  for (NSDictionary *fqlResult in response) {
    if ([[fqlResult valueForKey:@"name"] isEqualToString:@"query1"]) {
      albumArray = [fqlResult valueForKey:@"fql_result_set"];
    } else {
      // ignore
    }
  }
  _totalAlbumsToParse += [albumArray count];
  
  if ([response isKindOfClass:[NSArray class]]) {
    [_pendingResponses addObject:response];
  }
  
  _pendingRequestsToParse--;
  
  // If we have reached the last request, let's flush the pendingResponses
  if (_pendingRequestsToParse == 0) {
    [self parsePendingResponses];
  }
}

- (void)dataCenterRequestFailed:(ASIHTTPRequest *)request {
  // Inform Delegate
  if (_delegate && [_delegate respondsToSelector:@selector(dataCenterDidFail:withError:)]) {
    [_delegate performSelector:@selector(dataCenterDidFail:withError:) withObject:request withObject:[request error]];
  } 
}

- (void)dealloc {
  RELEASE_SAFELY(_pendingResponses);
  [super dealloc];
}

@end
