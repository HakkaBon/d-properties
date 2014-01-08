module property;

import std.conv, std.functional, std.typecons, std.typetuple;


/**
 * Signals and slots.
 *
 * Note: Works with structs as opposed to the std.signals implementation.
 *       Under the condition that only one client is connected at a time.
 *       May need further investigation here to remove that restriction.
 */
mixin template Signal(T...)
{
    /**
     * A slot is implemented as a delegate.
     * The slot_t is the type of the delegate.
     */
    alias void delegate(T) slot_t;

    /***
     * Call each of the connected slots, passing the argument(s) i to them.
     */
    void emit(T i) {
		if (slots) slots(i);
    }

    /**
     * Add a slot to the list of slots to be called when emit() is called.
     */
    void connect(slot_t slot) {
		slots = slot;
    }

    /**
     * Remove a slot from the list of slots to be called when emit() is called.
     */
    void disconnect(slot_t slot) {
		if (slots == slot) {   
			slots = null;
		}	
    }

  private:
    slot_t slots;	// the slots to call from emit()
}


/** 
 * Properties use the following access specifiers: 
 *  RW = Read and write, no restriction regarding reading writing.
 *  RO = Read only, rather meaningless, since it is essentially a derived property.
 *  WO = Write only, invisible property, any written value is made non-visible.
 */
enum PropertyAccess { RW, RO, WO }

/** 
 * Signals sent by properties.
 *  Changed = Sent by value properties, when its data is modified.
 *  Range Changed = Sent by dictinary properties, when its data range is 
 * 					changed, both growing and shrinking.
 */
enum PropertyEvent { Changed, RangeChanged }

/**
 * Read and write value property.
 */
struct ValueProperty(T, alias name, alias access)
{
	// actual value type of property
	alias T Type;

	// internal value representation
    private T mValue;

	// name of property
    private string mName;

	// access type of property
    private PropertyAccess mAccess;

	// declare signature of constraint method
	alias bool delegate(T) Constraint;
	
	// assign client's constaint method to this field  
	public Constraint constraint;  // = delegate bool (T value) { return true; }

	// various useful methods 
	public @property T value(T)()		{ return mValue; }
	public bool convertsTo(T)()			{ return mValue.convertsTo!(T)(); }
	public bool opEquals(T)(T rhs)		{ return mValue.opEquals!(T)(rhs); }
	public int opCmp(T)(T rhs)			{ return mValue.opCmp!(T)(rhs); }

	/**
	 *  Retrievs value with get method
	 *	Returns: The current value.
	 */	
	public T get() 
	{ 
		if (access == PropertyAccess.WO) return T.init;
		return mValue; 
	}

	/**
	 *  Assigns value with set method
	 *	Returns: The value assigned.
	 */	
	public T set(T value) 
	{ 
		if (value != mValue) 
		{
			if (access == PropertyAccess.RO) return value;
			if (constraint != null) if (!constraint(value)) return value;
			mValue = value;
			emit(this, value, name, PropertyEvent.Changed);
		}
		return value; 
	}
	
	/**
	 *  Dispatches all binary operators
	 *	Returns: The value assigned.
	 */	
	public T opBinary(string op)(T rhs) 					
	{ 
		static if (op == "=")
		{
			return opAssign(rhs);
		}
	}
	
	/**
	 *  Assigns value with assign operator
	 *	Returns: The value assigned.
	 */	
	public T opAssign(T rhs) 					
	{ 
		if (rhs != mValue) 
		{
			if (access == PropertyAccess.RO) return rhs;
			if (constraint != null) if (!constraint(rhs)) return rhs;
			mValue = rhs; 
			emit(this, rhs, name, PropertyEvent.Changed);
		}
		return rhs; 
	}

	/**
	 *	Returns a string representation of its current internal state.
	 *	Returns: The current value as a string.
	 */
	public string toString() { 
		if (access == PropertyAccess.WO) return "***";
		return to!string(mValue);
	}
	
	// mixin the code to send signals to listening objects
	mixin Signal!(typeof(this), T, string, PropertyEvent);
}


/**
 * Derived property.
 */
struct DerivedProperty(T, alias name)
{
	// actual value type of property
	alias T Type;

	// name of property
    private string mName;

	// various useful methods 
	public bool convertsTo(T)()			{ return evaluate().convertsTo!(T)(); }
	public bool opEquals(T)(T rhs)		{ return evaluate().opEquals!(T)(rhs); }
	public int opCmp(T)(T rhs)			{ return evaluate().opCmp!(T)(rhs); }

	// declare signature of derivation method
	alias T delegate() Evaluatator;
	
	// assign client's derivation method to this field  
	public Evaluatator evaluate;

	/**
	 *  Retrievs value with get method.
	 *	Returns: The current value.
	 */	
    public T get()
	{ 
		return evaluate(); 
	}

	/**
	 *	Returns a string representation of its current internal state.
	 *	Returns: The current value as a string.
	 */
	public string toString() { 
		return to!string(evaluate());
	}
}


/**
 * Indexed value property.
 */
struct DictionaryProperty(K, V, alias name, alias access) 
{
	// actual value type of property
	alias V Type;

	// internal value representation
    protected V[K] dict;
	
	// name of property
    private string mName;

	// access type of property
    private PropertyAccess mAccess;
	
	// declare signature of constraint method
	alias bool delegate(K,V) Constraint;

	// assign client's constaint method to this field  
	public Constraint constraint;

	// various useful methods 
	@property size_t length() { return dict.length; }
	@property string[] keys() { return dict.keys; }
	@property string[] values() { return dict.values; }

	/**
	 *	Removes an entry.
	 *
	 *	Params: k = The key to remove.
	 */
	public void remove(K k) {
		dict.remove(k); 
	}
	
	/**
	 *	Looks up a value with function call syntax.
	 *
	 *	Params: k = key to look up.
	 *	Returns: The corresponding value.
	 */
    public V get(K k) { 
		return dict[k]; 
	}
	
	/**
	 *	Looks up a value with operator syntax.
	 *
	 *	Params: k = The key to look up.
	 *	Returns: The corresponding value.
	 */
	public V opIndex(K k) {
		return dict[k]; 
	}
	
	/**
	 *	Sets a value with operator syntax 'dictionary[k] = v'.
	 *	
	 *	Params:
	 *	  k = key to set.
	 *	  v = value to assign to key.
	 *	Returns: V .
	 */
	public V set(K k, V v) { 
		if (k in dict) {
			if (constraint != null) if (!constraint(k,v)) return v;
			dict[k] = v;
			emit(this, v, name, PropertyEvent.Changed);
		} else {
			if (constraint != null) if (!constraint(k,v)) return v;
			dict[k] = v;
			emit(this, v, name, PropertyEvent.RangeChanged);
		}
		return v;
	}
	
	/**
	 *	Sets a value with operator syntax 'dictionary[k] = v'.
	 *
	 *	Params:
	 *	  k = key to set.
	 *	  v = value to assign to key.
	 *	Returns:    v.
	 */
	public V opIndexAssign(V v, K k) 
	{
		if (k in dict) 
		{
			if (constraint != null) if (!constraint(k,v)) return v;
			dict[k] = v;
			emit(this, v, name, PropertyEvent.Changed);
		} 
		else 
		{
			if (constraint != null) if (!constraint(k,v)) return v;
			dict[k] = v;
			emit(this, v, name, PropertyEvent.RangeChanged);
		}
		return v;
	}
	
	/**
	 *	Returns a string representation of its current internal state.
	 */
	public string toString() { 
		string s = "[";
		foreach (int i, k; keys) {
			s ~=  "(" ~ k ~ "," ~ get(k) ~ ")";
			if (i < length-1) s ~=  ",";
		}
		return s ~= "]";
	}
	
	// mixin the code to send signals to listening objects
	mixin Signal!(typeof(this), V, string, PropertyEvent);
}

