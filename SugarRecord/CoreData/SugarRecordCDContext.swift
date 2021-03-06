//
//  SugarRecordCDContext.swift
//  SugarRecord
//
//  Created by Pedro Piñera Buendía on 11/09/14.
//  Copyright (c) 2014 SugarRecord. All rights reserved.
//

import Foundation
import CoreData

public class SugarRecordCDContext: SugarRecordContext
{
    /// NSManagedObjectContext context
    let contextCD: NSManagedObjectContext
    
    /**
    SugarRecordCDContext initializer passing the CoreData context
    
    :param: context NSManagedObjectContext linked to this SugarRecord context
    
    :returns: Initialized SugarRecordCDContext
    */
    init (context: NSManagedObjectContext)
    {
        self.contextCD = context
    }
    
    /**
    Notifies the context that you're going to start an edition/removal/saving operation
    */
    public func beginWriting()
    {
       // CD begin writing does nothing
    }
    
    /**
    Notifies the context that you've finished an edition/removal/saving operation
    */
    public func endWriting()
    {
        var error: NSError?
        self.contextCD.save(&error)
        if error != nil {
            let exception: NSException = NSException(name: "Database operations", reason: "Couldn't perform your changes in the context", userInfo: ["error": error!])
            SugarRecord.handle(exception)
        }
    }
    
    /**
    Creates and object in the context (without saving)
    
    :param: objectClass Class of the created object
    
    :returns: The created object in the context
    */
    public func createObject(objectClass: AnyClass) -> AnyObject?
    {
        let managedObjectClass: NSManagedObject.Type = objectClass as NSManagedObject.Type
        var object: AnyObject = NSEntityDescription.insertNewObjectForEntityForName(managedObjectClass.entityName(), inManagedObjectContext: self.contextCD)
        return object
    }
    
    /**
    Insert an object in the context
    
    :param: object NSManagedObject to be inserted in the context
    */
    public func insertObject(object: AnyObject)
    {
        moveObject(object as NSManagedObject, inContext: self.contextCD)
    }
    
    /**
    Find NSManagedObject objects in the database using the passed finder
    
    :param: finder SugarRecordFinder usded for querying (filtering/sorting)
    
    :returns: Objects fetched
    */
    public func find(finder: SugarRecordFinder) -> [AnyObject]?
    {
        let fetchRequest: NSFetchRequest = SugarRecordCDContext.fetchRequest(fromFinder: finder)
        var error: NSError?
        var objects: [AnyObject]? = self.contextCD.executeFetchRequest(fetchRequest, error: &error)
        SugarRecordLogger.logLevelInfo.log("Found \(objects?.count) objects in database")
        return objects
    }
    
    /**
    Returns the NSFetchRequest from a given Finder
    
    :param: finder SugarRecord finder with the information about the filtering and sorting
    
    :returns: Created NSFetchRequest
    */
    public class func fetchRequest(fromFinder finder: SugarRecordFinder) -> NSFetchRequest
    {
        let objectClass: NSObject.Type = finder.objectClass!
        let managedObjectClass: NSManagedObject.Type = objectClass as NSManagedObject.Type
        let fetchRequest: NSFetchRequest = NSFetchRequest(entityName: managedObjectClass.entityName())
        fetchRequest.predicate = finder.predicate
        var sortDescriptors: [NSSortDescriptor] = finder.sortDescriptors
        switch finder.elements {
        case .first:
            fetchRequest.fetchLimit = 1
        case .last:
            if !sortDescriptors.isEmpty{
                sortDescriptors[0] = NSSortDescriptor(key: sortDescriptors.first!.key!, ascending: !(sortDescriptors.first!.ascending))
             }
            fetchRequest.fetchLimit = 1
        case .firsts(let number):
            fetchRequest.fetchLimit = number
        case .lasts(let number):
            if !sortDescriptors.isEmpty{
                sortDescriptors[0] = NSSortDescriptor(key: sortDescriptors.first!.key!, ascending: !(sortDescriptors.first!.ascending))
            }
            fetchRequest.fetchLimit = number
        case .all:
            break
        }
        fetchRequest.sortDescriptors = sortDescriptors
        return fetchRequest
    }
    
    /**
    Deletes a given object
    
    :param: object NSManagedObject to be deleted
    
    :returns: If the object has been properly deleted
    */
    public func deleteObject(object: AnyObject) -> SugarRecordContext
    {
        let managedObject: NSManagedObject? = object as? NSManagedObject
        let objectInContext: NSManagedObject? = moveObject(managedObject!, inContext: contextCD)
        if objectInContext == nil  {
            let exception: NSException = NSException(name: "Database operations", reason: "Imposible to remove object \(object)", userInfo: nil)
            SugarRecord.handle(exception)
        }
        SugarRecordLogger.logLevelInfo.log("Object removed from database")
        self.contextCD.deleteObject(managedObject!)
        return self
    }
    
    /**
    Deletes NSManagedObject objecs from an array
    
    :param: objects NSManagedObject objects to be dleeted
    
    :returns: If the deletion has been successful
    */
    public func deleteObjects(objects: [AnyObject]) -> ()
    {
        var objectsDeleted: Int = 0
        for object in objects {
            let _ = deleteObject(object)
        }
        SugarRecordLogger.logLevelInfo.log("Deleted \(objects.count) objects")
    }
    
    
    //MARK: - HELPER METHODS
    
    /**
    Moves an NSManagedObject from one context to another
    
    :param: object  NSManagedObject to be moved
    :param: context NSManagedObjectContext where the object is going to be moved to
    
    :returns: NSManagedObject in the new context
    */
    func moveObject(object: NSManagedObject, inContext context: NSManagedObjectContext) -> NSManagedObject?
    {
        var error: NSError?
        let objectInContext: NSManagedObject? = context.existingObjectWithID(object.objectID, error: &error)?
        if error != nil {
            let exception: NSException = NSException(name: "Database operations", reason: "Couldn't move the object into the new context", userInfo: nil)
            SugarRecord.handle(exception)
            return nil
        }
        else {
            return objectInContext
        }
    }
}