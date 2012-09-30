#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (EasyFetching)
- (NSArray *) fetchEntity:(NSString *)entityName withSortDescriptor:(NSSortDescriptor *)sortDescriptor fetchLimit:(NSInteger)fetchLimit predicate:(NSPredicate *)predicate;

@end
