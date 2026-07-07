# ADR-0006 Repository Structure

**Status:** Accepted

## Context

The folder structure for placing the roles in one of the ansible expected directories mentioned below or at the same level as the playbooks

```
<current playbook directory>/roles
~/.ansible/roles
/etc/ansible/roles
```

Directory structures included:

- Place roles under playbooks
- Place roles on same level as playbooks

## Decision

Separate playbooks from roles. Roles will be placed on the same level as playbooks.

## Alternatives Considered

### Place roles under playbooks.

Advantages

- Works out of the box.
- No configuration required.
- Simpler for beginners.

Disadvantages

- Tighter coupling between orchestration and implementation.
- The playbooks now "own" the roles.

### Place roles on same level as playbooks.

Advantages

- Playbooks orchestrate.
- Roles implement.
- This separation scales better.


Disadvantages

- Explicit configuration should be added in the ansible.cfg

## Consequences

Positive

- Follows industry recommendation

Negative

- Slightly cfg overhead

## References

Red Hat's recommendations
```
ansible/
├── inventories/
├── playbooks/
├── roles/
├── collections/
├── group_vars/
└── host_vars/
```