# ADR-0002 Configuration Management

**Status:** Accepted

## Context

Managing four nodes manually is feasible.

Managing eight or more nodes over several years is not.

Configuration drift must be avoided.

## Decision

Use Ansible as the configuration management platform.

## Alternatives Considered

### Shell Scripts

Advantages

- Simple
- No dependencies

Disadvantages

- Difficult to maintain
- Not idempotent
- Poor inventory management

### Puppet / Chef

Advantages

- Mature enterprise products

Disadvantages

- Agent-based
- Higher operational complexity

### SaltStack

Advantages

- Fast

Disadvantages

- Additional infrastructure

### Ansible

Advantages

- Agentless
- SSH-based
- Human-readable YAML
- Idempotent modules
- Excellent community

Disadvantages

- Slower than agent-based tools at very large scale

## Consequences

Positive

- Infrastructure as Code
- Repeatable deployments
- Easy onboarding

Negative

- Requires careful inventory design

## References

https://docs.ansible.com/