let Package = { 
	name : Text, 
	version : Text, 
	repo : Text, 
	dependencies : List Text 
}

-- This is where you can add/override existing packages in the package-set
-- For example, if you wanted to use version `v2.0.0` of the foo library:
let packages = [
	{ 
		name = "base", 
		repo = "https://github.com/dfinity/motoko-base", 
		version = "moc-0.7.2", 
		dependencies = [ "base" ]
  	},
	{ 
		name = "MultiValuedMap", 
		version = "main", 
		repo = "https://github.com/NatLabs/MultiValuedMap", 
		dependencies = [ "base" ] : List Text
	},
	{ 
		name = "Itertools", 
		version = "main", 
		repo = "https://github.com/NatLabs/Itertools.mo", 
		dependencies = [ "base" ] : List Text
	},
	{ 
		name = "json", 
		version = "v0.2.0", 
		repo = "https://github.com/aviate-labs/json.mo", 
		dependencies = [] : List Text
	},
	{ 
		name = "serde", 
		version = "main", 
		repo = "https://github.com/NatLabs/serde", 
		dependencies = [ "base" ] : List Text
	},
	{ 
		name = "http", 
		version = "v0.1.1", 
		repo = "https://github.com/aviate-labs/http.mo", 
		dependencies = [] : List Text
	},
	{ 
		name = "moh", 
		version = "main", 
		repo = "https://github.com/NatLabs/moh", 
		dependencies = [] : List Text
	},
] : List Package

in packages
