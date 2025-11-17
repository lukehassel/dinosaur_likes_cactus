import CoreData


//NS stands for NeXTSTEP. Called after the NeXT Computer which has been accuired by Apple.

// chmod +x dinosaur_entity.swift Makes it executable
// Run with swift dinosaur_entity.swift

func createDinosaurEntity() ->NSEntityDescription{
    let dinosaurEntity = NSEntityDescription()
    dinosaurEntity.name = "Dinosaur"
    dinosaurEntity.managedObjectClassName = "Dinosaur" // The name of the Swift class

    let nameAttr = NSAttributeDescription()
    nameAttr.name = "name"
    nameAttr.attributeType = .stringAttributeType
    nameAttr.isOptional = false

    let speciesAttr = NSAttributeDescription()
    speciesAttr.name = "species"
    speciesAttr.attributeType = .stringAttributeType
    speciesAttr.isOptional = false

    let weightAttr = NSAttributeDescription()
    weightAttr.name = "weight"
    weightAttr.attributeType = .doubleAttributeType
    weightAttr.isOptional = true

    let likesCactusAttr = NSAttributeDescription()
    likesCactusAttr.name = "likesCactus"
    likesCactusAttr.attributeType = .booleanAttributeType
    likesCactusAttr.isOptional = false
    likesCactusAttr.defaultValue = false

    // 3. Add the attributes to the entity blueprint
    dinosaurEntity.properties = [nameAttr, speciesAttr, weightAttr, likesCactusAttr]

    // DERIVED ATTRIBUTE: Display Name
    // Calculated on the fly. No Storage.
    // Concatenates name and species
    let displayNameAttr = NSDerivedAttributeDescription()
    displayNameAttr.name = "displayName"
    displayNameAttr.attributeType = .stringAttributeType

    // The derivation expression using Core Data's expression syntax
    displayNameAttr.derivationExpression = NSExpression(
        format: "name + ' the ' + species"
    )
    return dinosaurEntity
}

func createTorchEntity()->NSEntityDescription {
    // Create Torch Entity
    let torchEntity = NSEntityDescription()
    torchEntity.name = "Torch"
    torchEntity.managedObjectClassName = "Torch"

    let brightnessAttr = NSAttributeDescription()
    brightnessAttr.name = "brightness"
    brightnessAttr.attributeType = .integer16AttributeType // Brightness level 0-100

    torchEntity.properties = [brightnessAttr]

    return torchEntity
}

func setupRelationships(dinosaurEntity: NSEntityDescription, torchEntity: NSEntityDescription) {
    let dinosaurToTorch = NSRelationshipDescription()
    dinosaurToTorch.name = "torches"
    dinosaurToTorch.destinationEntity = torchEntity
    dinosaurToTorch.minCount = 0
    dinosaurToTorch.maxCount = 2
    dinosaurToTorch.deleteRule = .cascadeDeleteRule
    dinosaurToTorch.isOrdered = true

    let torchToDinosaur = NSRelationshipDescription()
    torchToDinosaur.name = "owner"
    torchToDinosaur.destinationEntity = dinosaurEntity
    torchToDinosaur.minCount = 0
    torchToDinosaur.maxCount = 1
    torchToDinosaur.deleteRule = .nullifyDeleteRule

    dinosaurToTorch.inverseRelationship = torchToDinosaur
    torchToDinosaur.inverseRelationship = dinosaurToTorch

    dinosaurEntity.properties.append(dinosaurToTorch)
    torchEntity.properties.append(torchToDinosaur)
}

func main() {

    let dinosaurEntity = createDinosaurEntity()
    let torchEntity = createTorchEntity()

    setupRelationships(dinosaurEntity: dinosaurEntity, torchEntity: torchEntity)

    // Create the Managed Object Model
    let model = NSManagedObjectModel()

    // Add entities to the model
    model.entities = [dinosaurEntity, torchEntity]


    // 1b. Create the Persistent Store Coordinator
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

    // Add an in-memory store (data won't persist)
    do {
        try coordinator.addPersistentStore(
            ofType: NSInMemoryStoreType,
            configurationName: nil,
            at: nil,
            options: nil
        )
    } catch {
        print("Failed to create store: \(error)")
        return
    }


    // 1c. Create the Managed Object Context (where model objects live!)
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator

    print("🦕🌵\n")

    let rex = NSManagedObject(entity: dinosaurEntity, insertInto: context)
    rex.setValue("Rex", forKey: "name")
    rex.setValue("T-Rex", forKey: "species")
    rex.setValue(7000.0, forKey: "weight")
    rex.setValue(false, forKey: "likesCactus")

    // Create torch for Rex
    let torch1 = NSManagedObject(entity: torchEntity, insertInto: context)
    torch1.setValue(100, forKey: "brightness")

    let torch2 = NSManagedObject(entity: torchEntity, insertInto: context)
    torch2.setValue(75, forKey: "brightness")

    let rexTorches = NSMutableOrderedSet()
    rexTorches.add(torch1)
    rexTorches.add(torch2)
    rex.setValue(rexTorches, forKey: "torches")

    // ========================================================================
    // Save the Context (Persist Changes)
    // ========================================================================

    do {
        try context.save()
        print("All model objects saved successfully!")
    } catch {
        print("Failed to save: \(error)")
    }


    // ========================================================================
    // Fetch Model Objects Back
    // ========================================================================

    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Dinosaur")
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "weight", ascending: false)]

    do {
        let dinosaurs = try context.fetch(fetchRequest)

        print("Found \(dinosaurs.count) dinosaurs in context:")
        for dino in dinosaurs {
            let name = dino.value(forKey: "name") as! String
            let species = dino.value(forKey: "species") as! String
            let weight = dino.value(forKey: "weight") as? Double ?? 0.0
            let torchCount = (dino.value(forKey: "torches") as? NSOrderedSet)?.count ?? 0

            print("  • \(name) the \(species) - \(weight) kg - \(torchCount) torch(es)")
        }

    } catch {
        print("Failed to fetch: \(error)")
    }

}

main()

