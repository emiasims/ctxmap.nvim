---@meta

---@alias ctxmap.ctx.fn fun(lhs: string?, keymap: ctxmap.keymap?):boolean?

---@alias ctxmap.ctx string|ctxmap.ctx.fn
---@alias ctxmap.rhs string|function

------ after processing / internal
---@class ctxmap.default.rule
---@field rhs ctxmap.rhs
---@field opts ctxmap.opts.rule Options for the rhs
---@field eat? string For abbreviations, a lua pattern to eat the input of.

---@class ctxmap.rule: ctxmap.default.rule
---@field ctx string|ctxmap.ctx.fn Context definition
---@field _ctx? ctxmap.ctx.fn Cached context function, if ctx is a string

---@class ctxmap.resolved.keymap
---@field lhs string
---@field opts { ctxmap: ctxmap.opts.ctxmap, keymap: ctxmap.opts.keymap, rule: ctxmap.opts.rule }
---@field mode string
---@field rules ctxmap.rule[]
---@field default { rhs: ctxmap.rhs, opts: ctxmap.opts.rule }

---@class ctxmap.keymap: ctxmap.resolved.keymap
---@field id string

------ options for specs
---@class ctxmap.opts.ctxmap: table
---@field dotrepeat? 'eval'|'repeat'|boolean
---@field count? 'eval'|'repeat'|boolean
---@field clear? boolean

---@class ctxmap.opts.keymap: table
---@field noremap? boolean
---@field remap? boolean
---@field silent? boolean
---@field nowait? boolean
---@field buffer? number|boolean
---@field desc? string|fun(keymap: ctxmap.keymap):string
---@field replace_keycodes? boolean

---@class ctxmap.opts.rule: table
---@field noremap? boolean
---@field remap? boolean
---@field silent? boolean
---@field expr? boolean
---@field desc? string|fun(keymap: ctxmap.keymap):string
---@field buffer? number|boolean

---@class ctxmap.opts: ctxmap.opts.ctxmap, ctxmap.opts.keymap, ctxmap.opts.rule
---@field eat? string
---@field mode? string|string[]
---@field ctx? ctxmap.ctx

------ spec definitions
---@class ctxmap.spec.rhs : ctxmap.opts.rule
---@field [1] ctxmap.rhs

---@class ctxmap.spec.rule: ctxmap.opts.rule
---@field [1] ctxmap.ctx
---@field [2] ctxmap.rhs|ctxmap.spec.rhs
---@field eat? string

---@class ctxmap.spec.keys: { [number]: ctxmap.spec.keys }, ctxmap.opts
---@field [1]? string lhs
---@field [2]? ctxmap.rhs|ctxmap.rule|ctxmap.rule[]
---@field default? ctxmap.rhs|ctxmap.spec.rhs
---@field mode? string|string[]
---@field ctx? ctxmap.ctx

---@class ctxmap.ctxlib: { [string]: ctxmap.ctx|table }

------ config
---@class ctxmap.config
---@field keys? ctxmap.spec.keys
---@field contexts? ctxmap.ctxlib
---@field libraries? table<string, string>
---@field extensions? table<string, boolean|table>
