class Dog
    attr_accessor :name, :breed, :id

    # The #initialize method accepts a hash or keyword argument value with key-value pairs as an argument. key-value pairs need to contain id, name, and breed.
    def initialize(attr_hash={})
        attr_hash.each do |key, value|
            if self.respond_to?("#{key.to_s}=")
                self.send("#{key.to_s}=", value)
            end
        end
    end

    # Your task here is to define a class method on Dog that will execute the correct SQL to create a dogs table.
    def self.create_table
        sql = "CREATE TABLE dogs (id INTEGER PRIMARY KEY, name TEXT, breed TEXT);"
        DB[:conn].execute(sql)
    end

    # This method will drop the dogs table from the database.
    def self.drop_table
        sql = "DROP TABLE IF EXISTS dogs;"
        DB[:conn].execute(sql)
    end

    # This spec ensures that given an instance of a dog, simply calling save will trigger the correct operation. To implement this, you will have to figure out a way for an instance to determine whether it has been persisted into the DB.
    # In the first test, we create an instance. Since it has never been saved before, specify that the instance will receive a method call to insert.
    # In the next test, we create an instance, save it, change its name, and then specify that a call to the save method should trigger an update.
    def save
        if !!self.id
            sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?;"
            DB[:conn].execute(sql, self.name, self.breed, self.id)
        else
            sql = "INSERT INTO dogs (name, breed) VALUES (? , ?);"
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].last_insert_row_id
        end
        self
    end

    def self.create(attr_hash={}) 
        dog = self.new(attr_hash) 
        dog.save
    end

    # This is an interesting method. Ultimately, the database is going to return an array representing a dog's data. We need a way to cast that data into the appropriate attributes of a dog. This method encapsulates that functionality. You can even think of it as new_from_array. Methods like this, that return instances of the class, are known as constructors, just like .new, except that they extend the functionality of .new without overwriting initialize.
    def self.new_from_db(row)
        id = row[0]
        name = row[1]
        breed = row[2]
        self.new(id: row[0], name: row[1], breed: row[2])
    end

    def self.find_by_id(id)
        sql = "SELECT * from dogs WHERE id = ?;"
        DB[:conn].execute(sql, id)[0].map do |row|
            self.new_from_db(row)
        end.first
    end

    # This method assumes that there isn't already a dog object matching these attributes, but that there may already exist a database entry with the same name and breed. Therefore, it instantiates a new instance of the Dog class while preventing a duplicate database entry.
    def self.find_or_create_by(name:, breed:)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?;", name, breed) # First, we query the database: does a record exist that has this name and breed?
        if dog.empty? # If such a record exists, then the statement: dog.empty? will return false and...
          dog = self.create(name: name, breed: breed)  # ...we will instead create and save a new Dog instance with the #create method.
        else # if no record exists that matches the name and breed passed in as arguments, then dog.empty? will return true and...
          dog_data = dog[0]  # We grab the dog_data from the dog array of arrays
          dog = Dog.new(id: dog_data[0], name: dog_data[1], row: dog_data[2]) # Then, we use this array to create a new Dog instance with the given id, name and breed.
        end
        dog # we will return the dog object whose database entry we either found or created
    end 

    #  This spec will first insert a dog into the database and then attempt to find it by calling the findbyname method. The expectations are that an instance of the dog class that has all the properties of a dog is returned, not primitive data.
    # Internally, what will the find_by_name method do to find a dog; which SQL statement must it run? Additionally, what method might find_by_name use internally to quickly take a row and create an instance to represent that data?
    def self.find_by_name(name)
        sql = "SELECT * FROM dogs WHERE name = ?;"
        DB[:conn].execute(sql, name).map do |row|
            self.new_from_db(row)
        end.first
    end

      # This spec will create and insert a dog, and afterwards, it will change the name of the dog instance and call update. The expectations are that after this operation, there is no dog left in the database with the old name. If we query the database for a dog with the new name, we should find that dog and the ID of that dog should be the same as the original, signifying this is the same dog, they just changed their name.
    def update
        sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?;"
        DB[:conn].execute(sql, self.name, self.breed, self.id)
    end
end