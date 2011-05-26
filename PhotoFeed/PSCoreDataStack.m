//
//  PSCoreDataStack.m
//  PhotoFeed
//
//  Created by Peter Shih on 2/16/11.
//  Copyright 2011 Seven Minute Apps. All rights reserved.
//

#import "PSCoreDataStack.h"

static NSPersistentStoreCoordinator *_persistentStoreCoordinator = nil;
static NSManagedObjectModel *_managedObjectModel = nil;
static NSManagedObjectContext *_mainThreadContext = nil;

@interface PSCoreDataStack (Private)

+ (void)resetStoreState;
+ (NSString *)applicationDocumentsDirectory;

@end

@implementation PSCoreDataStack

#pragma mark Initialization Methods
+ (void)resetPersistentStore {
  [[self class] deleteAllObjects:@"Album"];
  [[self class] deleteAllObjects:@"Photo"];
  [[self class] deleteAllObjects:@"Comment"];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kCoreDataDidReset object:nil];
  
  //  NSLog(@"reset persistent store and context");
  //  [self resetStoreState];
  //  [self resetManagedObjectContext];
}

+ (void)deleteAllObjects:(NSString *)entityDescription {
  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:entityDescription inManagedObjectContext:[[self class] mainThreadContext]];
  [fetchRequest setEntity:entity];
  
  NSError *error;
  NSArray *items = [[[self class] mainThreadContext] executeFetchRequest:fetchRequest error:&error];
  [fetchRequest release];
  
  
  for (NSManagedObject *managedObject in items) {
    [[[self class] mainThreadContext] deleteObject:managedObject];
  }
  if (![[[self class] mainThreadContext] save:&error]) {
  }
}

+ (void)resetStoreState {
  NSArray *stores = [_persistentStoreCoordinator persistentStores];
  
  for(NSPersistentStore *store in stores) {
    [_persistentStoreCoordinator removePersistentStore:store error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
  }
  
  [_managedObjectModel release];
  [_persistentStoreCoordinator release];
  _managedObjectModel = nil;
  _persistentStoreCoordinator = nil;
}

+ (void)resetManagedObjectContext {
  if (_mainThreadContext) {
    [_mainThreadContext release];
    _mainThreadContext = nil;
  }
  
  NSPersistentStoreCoordinator *coordinator = [[self class] persistentStoreCoordinator];
  NSManagedObjectContext *managedObjectContext = nil;
  if (coordinator != nil) {
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:coordinator];
  }
  
  _mainThreadContext = managedObjectContext;
}

#pragma mark Core Data Accessors
// shared static context
+ (NSManagedObjectContext *)mainThreadContext {
  NSAssert([NSThread isMainThread], @"mainThreadContext must be called from the main thread");
  
  if (_mainThreadContext != nil) {
    return _mainThreadContext;
  }
  
  // Use main thread
  NSPersistentStoreCoordinator *coordinator = [[self class] persistentStoreCoordinator];
  if (coordinator != nil) {
    _mainThreadContext = [[NSManagedObjectContext alloc] init];
    [_mainThreadContext setPersistentStoreCoordinator:coordinator];
  }
  
  return _mainThreadContext;
}

// returns a new retained context
+ (NSManagedObjectContext *)newManagedObjectContext {
  // Called on requesting thread
  
  NSPersistentStoreCoordinator *coordinator = [[self class] persistentStoreCoordinator];
  NSManagedObjectContext *context = nil;
  if (coordinator != nil) {
    context = [[NSManagedObjectContext alloc] init];
    [context setPersistentStoreCoordinator:coordinator];
  }
  
  // not autoreleased
  return context;
}

#pragma mark Save
+ (void)saveMainThreadContext {
  NSError *error = nil;
  if ([_mainThreadContext hasChanges]) {
    if (![_mainThreadContext save:&error]) {
      abort(); // NOTE: DO NOT SHIP
    }
  }
}

+ (void)saveInContext:(NSManagedObjectContext *)context {
  NSError *error = nil;
  if ([context hasChanges]) {
    if (![context save:&error]) {
      abort(); // NOTE: DO NOT SHIP
    }
  }
}

#pragma mark Accessors
+ (NSManagedObjectModel *)managedObjectModel {
  if (_managedObjectModel != nil) {
    return _managedObjectModel;
  }
  
  NSString *path = [[NSBundle mainBundle] pathForResource:@"PhotoFeed" ofType:@"momd"];
  NSURL *momURL = [NSURL fileURLWithPath:path];
  _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
  
  return _managedObjectModel;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  if(_persistentStoreCoordinator != nil) {
    return _persistentStoreCoordinator;
  }
  
  // Create a new persistent store
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[[self class] managedObjectModel]];
  
  NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
  
  NSURL *storeURL = [NSURL fileURLWithPath:[[[self class] applicationDocumentsDirectory] stringByAppendingPathComponent:@"PhotoFeed.sqlite"]];
  
  NSError *error = nil;
  
  if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
    // Handle the error.
    NSLog(@"failed to create persistent store");
    abort(); // NOTE: DON'T SHIP THIS
  } else {
    NSLog(@"init persistent store with path: %@", storeURL);
  }
  
  return _persistentStoreCoordinator;
}

#pragma mark Convenience Methods
+ (NSString *)applicationDocumentsDirectory {
  return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

@end
