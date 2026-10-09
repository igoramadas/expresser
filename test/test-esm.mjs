import assert from "node:assert/strict"
import {createRequire} from "node:module"
import expresser from "expresser"

const require = createRequire(import.meta.url)

assert.strictEqual(expresser, require("expresser"))
assert.equal(typeof expresser.app.init, "function")
assert.equal(typeof expresser.routes.load, "function")
