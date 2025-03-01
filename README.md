# About

![Build status](https://github.com/alexs-sh/policy-format/actions/workflows/build.yml/badge.svg)

A small tool to keep SELinux policy files consistently formatted. It’s not a
full-featured formatter—I just had some messy TE files, free time, and wanted to
experiment.

# Example

### Before

```
policy_module(super_module, 1.0)

# comment
require {
    type bin_t;
    type kernel_t ;
    class dir {  lock map open execute open lock execute};
}

init_daemon_domain(super_module_t, super_module_exec_t) ; # comment
allow super_module self:dir { execute lock lock lock   };
```

```
super_module.te:      4: (S): Require block used in te file (use an interface call instead) (S-001)
super_module.te:      7: (C): Permissions in class declaration not ordered (open before execute) (C-005)
super_module.te:     10: (S): Unnecessary semicolon (S-003)
super_module.te:     11: (C): Permissions in av rule repeated (lock) (C-005)
```

### After

```
policy_module(super_module, 1.0)

# comment
require {
    type bin_t;
    type kernel_t;
    class dir { execute lock map open };
}

init_daemon_domain(super_module_t, super_module_exec_t)  # comment
allow super_module self:dir { execute lock };
```


```
super_module.te:      4: (S): Require block used in te file (use an interface call instead) (S-001)
```

# Usage

Format and print to stdout

```
policy-format input.te
```

Format and save output to a file

```
policy-format input.te output.te
```

# Build

```
ghc ./policy-format.hs
```
