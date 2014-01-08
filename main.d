module example;

// phobos imports
import std.functional, std.stdio, std.typetuple, std.typecons;

// property imports
import property;


/**
 *  Example Car class with properties.
 */
class Car {
	
	// Which property and what value changed with what kind of modification.
	// Dependencies among properties are handled here.
	public void changeEvent(T,U)(T property, U data, string name, PropertyEvent event)
	{
		switch (name) {
			case "name": 	
			case "speed": 	
			case "color": 	
			case "accel": 	
			case "something": 	
			case "lookup": 	
			default:
				writeln("name: '",name,"' value: '",data,"' [", event,"]");
		}
	}

    // Derive calculated property from acceleration
    public double calculate() {
        return (properties.accel.get() * 17 / 3);
    }
	
    // Constraint: validate colour
    public bool ColorConstraint(int v) {
		return (0 <= v && v < 256) ? true : false;
    }

    // Constraint: NoConstraint func (return true all the time)
    public bool NoConstraint(T)(T value) {
		return true;
    }
	
	// All properties are specified as (property spec, property name)-tuples.
	Tuple!(
		ValueProperty!(string,"name",PropertyAccess.WO), "name", 
		ValueProperty!(double,"speed",PropertyAccess.RW), "speed", 
		ValueProperty!(int,"color",PropertyAccess.RO), "color",
		ValueProperty!(double,"accel",PropertyAccess.RW), "accel",
		DerivedProperty!(double,"something"), "something",
		DictionaryProperty!(string,string,"lookup",PropertyAccess.RW), "lookup"
	) properties; 
	
	this() {
		// set (any) constraints
		properties.name.constraint = &NoConstraint!string;
		properties.speed.constraint = &NoConstraint!double;
		properties.color.constraint = &ColorConstraint;
		properties.accel.constraint = &NoConstraint!double;

		// set calculation method for derived properties
		properties.something.evaluate = &calculate;
		
		// connect property methods to its event observers
		properties.name.connect(&changeEvent!(typeof(properties.name), properties.name.Type));
		properties.speed.connect(&changeEvent!(typeof(properties.speed), properties.speed.Type));
		properties.color.connect(&changeEvent!(typeof(properties.color), properties.color.Type));
		properties.accel.connect(&changeEvent!(typeof(properties.accel), properties.accel.Type));
		properties.lookup.connect(&changeEvent!(typeof(properties.lookup), properties.lookup.Type));
	}
}

void main()
{	   
	Car car = new Car;

	// property referred to by its index
    car.properties[0] = "Ferrari";
    car.properties[1] = 320;
    car.properties[2] = 1;
    car.properties[3] = 44.5;
    car.properties[5]["Volvo"] = "Geele";

	// print all properties
	foreach (int i, p ; car.properties) writeln("property [",i, "] = ", p.toString());

	// property referred to by its name
    car.properties.name = "VW";
    car.properties.speed = 150;
    car.properties.color = 3;
    car.properties.accel = 23.0;
    car.properties.lookup["Saab"] = "Panda";

	// print all properties
	foreach (int i, p ; car.properties) writeln("property [",i, "] = ", p.toString());
}
