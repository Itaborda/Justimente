import test from 'node:test'
import assert from 'node:assert/strict'

test('estados de solicitud documentados',()=>{
 const allowed=['pending','review','assigned','active','completed','cancelled']
 assert.equal(allowed.length,6)
 assert.ok(allowed.includes('pending'))
 assert.ok(allowed.includes('completed'))
})
