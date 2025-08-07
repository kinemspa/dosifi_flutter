# Dosifi Developer Documentation

## Overview
This document provides developers with information about the Dosifi Flutter application architecture, development guidelines, and references to detailed technical specifications.

## Architecture Overview

Dosifi follows a clean architecture pattern with clear separation of concerns:

### Layer Structure
- **Presentation Layer**: UI screens, widgets, and Riverpod providers
- **Business Logic Layer**: Services and use cases
- **Data Layer**: Repositories, models, and database management

### Key Technologies
- **Flutter/Dart**: Cross-platform mobile development
- **Riverpod**: State management and dependency injection
- **SQLCipher**: Encrypted local database storage
- **GoRouter**: Navigation and routing
- **Material Design 3**: UI components and theming

## Core Features

### Medication Management System
The app supports 13 different medication types, each with specific tracking algorithms:
- Tablets, Capsules, Liquids, Injectables
- Lyophilized vials with reconstitution calculations
- Patches, Inhalers, Topical medications
- Custom "Other" type for flexibility

### Advanced Calculations
- **Dose Scheduling**: Automated dose log generation
- **Stock Management**: Real-time inventory tracking with deduction
- **Reconstitution Calculator**: Complex dilution calculations
- **Compliance Analytics**: Adherence rate calculations

### Security Features
- **Data Encryption**: SQLCipher for database encryption
- **Secure Storage**: Flutter Secure Storage for sensitive keys
- **Input Validation**: Multi-layer validation system

## Confidential Technical Documentation

### ⚠️ INTERNAL USE ONLY
The following files contain proprietary business logic, algorithms, and detailed implementation specifications. These documents are restricted to authorized developers only:

#### Core Architecture Documents
- **`DOSIFI_ARCHITECTURE_MATRIX.md`**
  - Complete system architecture breakdown
  - Component integration matrix
  - Data flow diagrams
  - Service layer specifications
  - Provider relationship mappings

#### Medication System Specifications
- **`MEDICATION_TYPES_BREAKDOWN.md`**
  - Detailed breakdown of all 13 medication types
  - Input requirements and validation rules
  - Calculation algorithms and formulas
  - Real-world usage examples
  - Type-specific UI considerations

- **`MEDICATION_TRACKING_MATRIX.md`**
  - Comprehensive tracking specifications
  - Stock calculation methods
  - Dose precision requirements
  - Unit conversion algorithms
  - Compliance tracking formulas

#### Excel Reference Files
- **`Dosifi_Medication_Tracking_Matrix.csv`**
  - Excel-compatible medication tracking matrix
  - Sortable and filterable specifications
  - Calculation reference tables

- **`Dosifi_Tracking_Calculations.csv`**
  - Mathematical formulas and algorithms
  - Compliance tracking methods
  - Storage and application guidelines

### Access Requirements
These documents contain:
- Proprietary medication management algorithms
- Business logic implementations
- Detailed calculation formulas
- Competitive advantage information

**Access is restricted to**:
- Core development team members
- Technical leads and architects
- Authorized consultants with signed NDAs

### Usage Guidelines
1. **Do not share** these documents outside the authorized team
2. **Do not commit** these files to public repositories
3. **Reference only** general concepts in public documentation
4. **Maintain confidentiality** of specific algorithms and calculations

## Development Guidelines

### Code Standards
- Follow Dart/Flutter best practices
- Use consistent naming conventions
- Implement proper error handling
- Write comprehensive unit tests
- Document public APIs

### State Management
- Use Riverpod for all state management
- Implement proper provider disposal
- Handle loading and error states
- Cache data appropriately

### Database Operations
- Use repository pattern for data access
- Implement proper transaction handling
- Validate all inputs before database operations
- Handle migration scenarios properly

### Security Considerations
- Never log sensitive data
- Validate all user inputs
- Use secure storage for sensitive information
- Implement proper encryption for data at rest

## Testing Strategy

### Unit Tests
- Test all business logic components
- Mock external dependencies
- Test edge cases and error conditions
- Maintain high code coverage

### Integration Tests
- Test database operations
- Test provider interactions
- Test navigation flows
- Test calculation accuracy

### Widget Tests
- Test UI components
- Test user interactions
- Test responsive layouts
- Test accessibility features

## Deployment

### Build Configuration
- Use proper signing certificates
- Configure obfuscation for release builds
- Optimize app size and performance
- Test on multiple device configurations

### Security Checklist
- Verify encryption is enabled
- Check for debug information removal
- Validate certificate configurations
- Test data protection measures

## Contributing

### Getting Started
1. Review this developer documentation
2. Request access to confidential specifications
3. Set up development environment
4. Review existing code architecture
5. Start with small, well-defined tasks

### Pull Request Process
1. Create feature branch from main
2. Implement changes with tests
3. Update documentation if needed
4. Request code review from team lead
5. Merge after approval and CI passes

### Code Review Guidelines
- Review for security vulnerabilities
- Verify algorithm implementations
- Check performance implications
- Validate test coverage
- Ensure documentation is updated

## Support and Contacts

For technical questions regarding:
- **Architecture decisions**: Contact technical lead
- **Medication algorithms**: Request access to confidential docs
- **Database design**: Review data layer documentation
- **UI/UX implementation**: Refer to design system guidelines

---

**Note**: This document provides general development guidance. Detailed implementation specifications are available in the confidential documentation files listed above, accessible to authorized team members only.

Last Updated: January 2025
