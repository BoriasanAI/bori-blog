'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const code = fs.readFileSync('assets/js/reader-visuals.js', 'utf8');
const messages = [];
const figure = { querySelector: () => messages[0] };
const image = {
  complete: true, naturalWidth: 0, hidden: false,
  closest: () => figure,
  addEventListener(name, callback) { assert.equal(name, 'error'); this.failure = callback; },
  after(message) { messages.push(message); }
};
const document = {
  readyState: 'complete',
  querySelectorAll: () => [image],
  createElement: () => ({ setAttribute(name, value) { this[name] = value; } })
};
vm.runInNewContext(code, { document });
assert.equal(image.hidden, true);
assert.equal(messages.length, 1);
assert.equal(messages[0].role, 'status');
assert.match(messages[0].textContent, /Source and attribution remain/);
image.failure();
assert.equal(messages.length, 1);
image.complete = false;
image.hidden = false;
messages.length = 0;
vm.runInNewContext(code, { document });
assert.equal(messages.length, 0);
assert.equal(image.hidden, false);
console.log('visual-reader-js: 7 checks passed');
