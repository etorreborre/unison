# Tests for `move`

## Happy Path - namespace, term, and type

Create a term, type, and namespace with history

```unison
Foo = 2
unique type Foo = Foo
Foo.termInA = 1
unique type Foo.T = T
```

```ucm

  Loading changes detected in scratch.u.

  I found and typechecked these definitions in scratch.u. If you
  do an `add` or `update`, here's how your codebase would
  change:
  
    ⍟ These new definitions are ok to `add`:
    
      type Foo
      type Foo.T
      Foo         : Nat
      Foo.termInA : Nat

```
```ucm
.> add

  ⍟ I've added these definitions:
  
    type Foo
    type Foo.T
    Foo         : Nat
    Foo.termInA : Nat

```
```unison
Foo.termInA = 2
unique type Foo.T = T1 | T2
```

```ucm

  Loading changes detected in scratch.u.

  I found and typechecked these definitions in scratch.u. If you
  do an `add` or `update`, here's how your codebase would
  change:
  
    ⍟ These names already exist. You can `update` them to your
      new definition:
    
      type Foo.T
      Foo.termInA : Nat
        (also named Foo)

```
```ucm
.> update

  Okay, I'm searching the branch for code that needs to be
  updated...

  Done.

```
Should be able to move the term, type, and namespace, including its types, terms, and sub-namespaces.

```ucm
.> move Foo Bar

  Done.

.> ls

  1. Bar      (Nat)
  2. Bar      (type)
  3. Bar/     (4 terms, 1 type)
  4. builtin/ (467 terms, 74 types)

.> ls Bar

  1. Foo     (Bar)
  2. T       (type)
  3. T/      (2 terms)
  4. termInA (Nat)

.> history Bar

  Note: The most recent namespace hash is immediately below this
        message.
  
  ⊙ 1. #o7vuviel4c
  
    + Adds / updates:
    
      T T.T1 T.T2 termInA
    
    - Deletes:
    
      T.T
  
  □ 2. #c5cggiaumo (start of history)

```
## Happy Path - Just term

```unison
bonk = 5
```

```ucm

  Loading changes detected in scratch.u.

  I found and typechecked these definitions in scratch.u. If you
  do an `add` or `update`, here's how your codebase would
  change:
  
    ⍟ These new definitions are ok to `add`:
    
      bonk : Nat

```
```ucm
  ☝️  The namespace .z is empty.

.z> builtins.merge

  Done.

.z> add

  ⍟ I've added these definitions:
  
    bonk : Nat

.z> move bonk zonk

  Done.

.z> ls

  1. builtin/ (467 terms, 74 types)
  2. zonk     (Nat)

```
## Happy Path - Just namespace

```unison
bonk.zonk = 5
```

```ucm

  Loading changes detected in scratch.u.

  I found and typechecked these definitions in scratch.u. If you
  do an `add` or `update`, here's how your codebase would
  change:
  
    ⍟ These new definitions are ok to `add`:
    
      bonk.zonk : Nat
        (also named zonk)

```
```ucm
  ☝️  The namespace .a is empty.

.a> builtins.merge

  Done.

.a> add

  ⍟ I've added these definitions:
  
    bonk.zonk : Nat

.a> move bonk zonk

  Done.

.a> ls

  1. builtin/ (467 terms, 74 types)
  2. zonk/    (1 term)

.a> view zonk.zonk

  zonk.zonk : Nat
  zonk.zonk = 5

```
## Sad Path - No term, type, or namespace named src

```ucm
.> move doesntexist foo

  ⚠️
  
  There is no term, type, or namespace at doesntexist.

```
