---@class user
package.user = package.user or {}

--- Whether setup is done or not
package.user.setup_done = package.user.setup_done

---@class user.state
---@field terminal { id: {[integer]: terminal}, pid: {[integer]: terminal} }
---@field autocmd {[integer]: autocmd}
---@field keymap keymap[]
---@field repl {[string]: {[string]: terminal}}
---@field command command[]
package.user.state = package.user.state or {}

---@class user.config
---@field plugins table
---@field workspace {check_depth: integer, markers: string[]|string}
package.user.config = package.user.config or {}

---Contains my bespoke API
---@class user.lib
package.user.lib = package.user.lib
package.user.lib.assert = package.user.lib.assert or require 'lua-utils.assert'
package.user.lib.pack = package.user.lib.pack
package.user.lib.unlink = package.user.lib.unlink
package.user.lib.abspath = package.user.lib.abspath
package.user.lib.is_plist = package.user.lib.is_plist
package.user.lib.is_pdict = package.user.lib.is_pdict
package.user.lib.is_ptable = package.user.lib.is_ptable
package.user.lib.is_mount = package.user.lib.is_mount
package.user.lib.is_link = package.user.lib.is_link
package.user.lib.is_file = package.user.lib.is_file
package.user.lib.is_dir = package.user.lib.is_dir
package.user.lib.dirname = package.user.lib.dirname
package.user.lib.basename = package.user.lib.basename
package.user.lib.list_files = package.user.lib.list_files
package.user.lib.glob = package.user.lib.glob
package.user.lib.filetype = package.user.lib.filetype
package.user.lib.validate = package.user.lib.validate
package.user.lib.class = package.user.lib.class
package.user.lib.maybe = package.user.lib.maybe
package.user.lib.optional = package.user.lib.optional
package.user.lib.union = package.user.lib.union
package.user.lib.is = package.user.lib.is
package.user.lib.isa = package.user.lib.isa
package.user.lib.as = package.user.lib.as
package.user.lib.defcallable = package.user.lib.defcallable
package.user.lib.deftype = package.user.lib.deftype
package.user.lib.defguard = package.user.lib.defguard
package.user.lib.defmulti = package.user.lib.defmulti
package.user.lib.defclass = package.user.lib.defclass
package.user.lib.foreach = package.user.lib.foreach
package.user.lib.callable = package.user.lib.callable
package.user.lib.hasmetatable = package.user.lib.hasmetatable
package.user.lib.classof = package.user.lib.classof
package.user.lib.instanceof = package.user.lib.instanceof
package.user.lib.isa = package.user.lib.isa
package.user.lib.reduce = package.user.lib.reduce
package.user.lib.reverse = package.user.lib.reverse
package.user.lib.typeof = package.user.lib.typeof
package.user.lib.is_subclass = package.user.lib.is_subclass
package.user.lib.unique = package.user.lib.unique
package.user.lib.mt_get = package.user.lib.mt_get
package.user.lib.mt_set = package.user.lib.mt_set
package.user.lib.has_mt = package.user.lib.has_mt
package.user.lib.get_mt = package.user.lib.get_mt
package.user.lib.set_mt = package.user.lib.set_mt
package.user.lib.callable = package.user.lib.callable
package.user.lib.bless = package.user.lib.bless
package.user.lib.types = package.user.lib.types
package.user.lib.list = package.user.lib.list
package.user.lib.dict = package.user.lib.dict
package.user.lib.copy = package.user.lib.copy
package.user.lib.tuple = package.user.lib.tuple
package.user.lib.set = package.user.lib.set
package.user.lib.NIL = package.user.lib.NIL
package.user.lib.GUARD = package.user.lib.GUARD
package.user.lib.unpack = package.user.lib.unpack
package.user.lib.is_table = package.user.lib.is_table
package.user.lib.is_string = package.user.lib.is_string
package.user.lib.is_userdata = package.user.lib.is_userdata
package.user.lib.is_function = package.user.lib.is_function
package.user.lib.is_list = package.user.lib.is_list
package.user.lib.is_dict = package.user.lib.is_dict
package.user.lib.is_guard = package.user.lib.is_guard
package.user.lib.is_boolean = package.user.lib.is_boolean
package.user.lib.is_class = package.user.lib.is_class
package.user.lib.is_instance = package.user.lib.is_instance
package.user.lib.is_builtin_type = package.user.lib.is_builtin_type
package.user.lib.is_object = package.user.lib.is_object
package.user.lib.is_union = package.user.lib.is_union
package.user.lib.is_pure_list = package.user.lib.is_pure_list
package.user.lib.is_pure_dict = package.user.lib.is_pure_dict
package.user.lib.is_pure_table = package.user.lib.is_pure_table
package.user.lib.is_thread = package.user.lib.is_thread
package.user.lib.fs = package.user.lib.fs
package.user.lib.path = package.user.lib.path
package.user.lib.system = package.user.lib.system
package.user.lib.systemlist = package.user.lib.systemlist
package.user.lib.process = package.user.lib.process
package.user.lib.inspect = package.user.lib.inspect
package.user.lib.result = package.user.lib.result
package.user.lib.Ok = package.user.lib.Ok
package.user.lib.Err = package.user.lib.Err
package.user.lib.str = package.user.lib.str
package.user.lib.metatable = package.user.lib.metatable
package.user.lib.NIL = package.user.lib.NIL
package.user.lib.GUARD = package.user.lib.GUARD
package.user.lib.BACKUP = package.user.lib.BACKUP
package.user.lib.BUILTIN_TYPES = package.user.lib.BUILTIN_TYPES

---@type {[string]: string}
package.user.state.workspace = package.user.state.workspace or {}

---@type {[string]: filetype}
package.user.config.filetype = package.user.config.filetype or {}
