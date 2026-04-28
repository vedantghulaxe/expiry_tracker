# Team Allocation - Expiry Tracker App

## Overview

This document divides the Expiry Tracker App project among 4 team members based on files, complexity, and contribution areas.

---

## Member 1: UI/Presentation Layer

**Role:** Frontend Developer
**Complexity:** Medium
**Files to Handle:** ~15 files

### Responsibilities:
- All Flutter screens and widgets
- User interface design
- Navigation flow
- Form validation
- User interactions

### Files:

```
lib/features/
├── common/
│   ├── barcode_scanner_screen.dart
│   ├── image_capture_screen_real_ocr.dart
│   └── home_screen.dart
├── product/
│   ├── product_entry_method_screen.dart
│   ├── manual_product_entry_screen.dart
│   ├── product_form_screen_new.dart
│   └── product_list_screen.dart
└── settings/
    ├── settings_screen.dart
    └── notification_settings_screen.dart
```

### Key Tasks:
1. **Barcode Scanner Screen**
   - Implement camera preview
   - Handle barcode detection
   - Add manual barcode entry dialog
   - Handle scan results

2. **Image Capture Screen**
   - Camera/gallery integration
   - Image preview
   - Progress indicators
   - Analysis results display

3. **Product Forms**
   - Form validation
   - Date pickers
   - Auto-fill from AI data
   - Image attachment

4. **Home Screen**
   - Product list display
   - Expiry status indicators (red/orange/green)
   - Search and filter
   - Swipe actions

**Estimated Effort:** 40% of total work

---

## Member 2: AI & OCR Services

**Role:** AI/ML Engineer
**Complexity:** High
**Files to Handle:** ~8 files

### Responsibilities:
- AI vision integration (Oxlo.ai)
- OCR pipeline implementation
- Image processing
- Text extraction and parsing
- Retry logic for network resilience

### Files:

```
lib/core/services/
├── ai_service.dart
├── robust_ocr_service.dart
└── logger_service.dart

lib/services/
└── multi_image_service_simple.dart

lib/core/services/ocr/
├── ml_kit_service.dart
└── tesseract_service.dart
```

### Key Tasks:
1. **AIService (Oxlo.ai Integration)**
   - API integration with Oxlo.ai
   - Vision model integration (ministral-14b)
   - Text model integration (mistral-7b)
   - Prompt engineering for accurate extraction
   - Retry logic with exponential backoff
   - Error handling for network issues

2. **RobustOCRService**
   - Multi-stage OCR pipeline
   - Online/offline switching
   - Image validation
   - Confidence scoring
   - Structured data extraction

3. **Multi-Image Processing**
   - Batch image processing
   - Progress tracking
   - Result merging from multiple images

4. **OCR Engines**
   - Google ML Kit integration
   - Tesseract OCR setup
   - Fallback mechanisms

**Estimated Effort:** 25% of total work

---

## Member 3: Data Layer & APIs

**Role:** Backend/Data Engineer
**Complexity:** High
**Files to Handle:** ~10 files

### Responsibilities:
- Database management (Drift/SQLite)
- Repository pattern implementation
- Public API integration (Open Food Facts, FDA, UPCItemDB)
- Barcode lookup service
- Data models

### Files:

```
lib/data/
├── database/
│   └── app_database.dart
└── repositories/
    └── product_repository.dart

lib/core/services/
├── database_service.dart
├── barcode_service.dart
├── product_api_service.dart
└── image_validation_service.dart

lib/models/
├── product_info.dart
└── product_model.dart
```

### Key Tasks:
1. **Database Service**
   - Drift ORM setup
   - CRUD operations
   - Query optimization
   - Database migrations

2. **Product Repository**
   - Repository pattern implementation
   - Business logic layer
   - Caching strategy
   - Batch operations

3. **Product API Service**
   - Open Food Facts API integration
   - FDA Drug Database integration
   - UPCItemDB integration
   - Smart lookup with fallback
   - Expiry date extraction from APIs

4. **Barcode Service**
   - Local Indian medicine database (10+ medicines)
   - Barcode format validation
   - API lookup coordination
   - AI fallback for unknown barcodes

5. **Image Validation Service**
   - Image quality checks
   - Product label detection
   - Confidence scoring

**Estimated Effort:** 20% of total work

---

## Member 4: Core Services & Utilities

**Role:** Core/Utility Developer
**Complexity:** Medium
**Files to Handle:** ~12 files

### Responsibilities:
- Configuration management
- Local text parsing (regex)
- Utility functions
- Notifications
- State management setup
- Common helpers

### Files:

```
lib/core/services/
├── config_service.dart
├── local_parser_service.dart
└── notification_service.dart

lib/core/utils/
├── ui_helpers.dart
├── date_helpers.dart
├── string_helpers.dart
└── constants.dart

lib/bloc/
├── product_bloc.dart
├── product_event.dart
└── product_state.dart

lib/providers/
├── product_provider.dart
└── settings_provider.dart
```

### Key Tasks:
1. **Config Service**
   - API key management
   - App settings
   - Configuration persistence

2. **Local Parser Service**
   - Regex pattern matching for dates
   - Product name extraction
   - Batch number detection
   - Brand/manufacturer extraction
   - Multiple date format support (DD/MM/YYYY, MM/YYYY, DDMMMYY)

3. **Notification Service**
   - Local notification setup
   - Expiry reminder scheduling
   - Notification channels
   - Time-based triggers

4. **Utility Functions**
   - Date formatting and parsing
   - String manipulation helpers
   - UI helpers (show dialogs, snackbars)
   - Constants and enums

5. **State Management**
   - BLoC pattern implementation
   - Provider setup
   - State management for products
   - Event handling

**Estimated Effort:** 15% of total work

---

## Cross-Team Dependencies

### Dependency Graph:

```
Member 4 (Core Services)
    ↓ provides utilities to
Member 2 (AI/OCR) ←→ Member 3 (Data Layer)
    ↓ provides data to
Member 1 (UI Layer)
```

### Integration Points:

1. **Member 4 → Member 2:**
   - ConfigService provides API keys to AIService
   - LocalParserService provides regex patterns to RobustOCRService

2. **Member 2 → Member 3:**
   - RobustOCRService provides extracted data to ProductRepository
   - AIService provides structured data to DatabaseService

3. **Member 3 → Member 1:**
   - ProductRepository provides data to screens
   - BarcodeService provides lookup results to forms

4. **Member 4 → Member 1:**
   - UI Helpers used across all screens
   - Notification Service used in Home Screen

---

## Development Timeline

### Week 1: Setup & Core Services
- **Member 4:** Setup project structure, constants, utilities
- **Member 3:** Database setup, repository pattern
- **Member 2:** AI service integration (Oxlo.ai)
- **Member 1:** Basic UI screens (home, settings)

### Week 2: Core Features
- **Member 3:** Barcode service, API integrations
- **Member 2:** OCR pipeline, image processing
- **Member 4:** Local parser, notification service
- **Member 1:** Barcode scanner screen, form screens

### Week 3: Advanced Features
- **Member 2:** Multi-image processing, retry logic
- **Member 3:** Local medicine database, caching
- **Member 4:** State management, advanced utilities
- **Member 1:** Image capture screen, auto-fill forms

### Week 4: Integration & Testing
- **All Members:** Integration testing
- **Member 1:** UI polish, animations
- **Member 2:** Error handling, logging
- **Member 3:** Data validation, migrations
- **Member 4:** Performance optimization, bug fixes

---

## Communication & Collaboration

### Daily Standups
- Discuss progress
- Identify blockers
- Coordinate integration points

### Code Reviews
- Each member reviews code from at least 1 other member
- Focus on integration points
- Ensure consistent code style

### Shared Responsibilities
- All members: Bug fixes, testing, documentation
- Member 1 & 3: UI/UX consistency
- Member 2 & 4: Performance optimization
- Member 3 & 4: Data validation

---

## File Ownership Summary

| Member | Files | Complexity | Effort % |
|--------|-------|------------|----------|
| 1 | 15 | Medium | 40% |
| 2 | 8 | High | 25% |
| 3 | 10 | High | 20% |
| 4 | 12 | Medium | 15% |

**Total Files:** ~45 files
**Total Complexity:** Balanced across team
**Estimated Timeline:** 4 weeks

---

## Risk Mitigation

### Single Point of Failure
- Each service has fallback mechanisms
- Knowledge sharing through code reviews
- Documentation for critical components

### Integration Risks
- Define clear interfaces between modules
- Early integration testing (Week 2)
- Mock services for parallel development

### Skill Gaps
- Cross-training sessions
- Pair programming for complex tasks
- Documentation for all services

---

## Success Metrics

1. **Code Quality:**
   - All tests passing
   - Code coverage > 80%
   - No critical bugs

2. **Performance:**
   - App launch time < 3 seconds
   - OCR processing < 5 seconds
   - Barcode lookup < 2 seconds

3. **User Experience:**
   - Smooth navigation
   - Clear error messages
   - Intuitive forms

4. **Team Collaboration:**
   - Daily standups attended
   - Code reviews completed
   - Documentation up to date

---

## Contact & Coordination

### Project Manager
- Overall coordination
- Timeline tracking
- Risk management

### Tech Lead (Member 2)
- Technical decisions
- Code quality
- Architecture oversight

### Git Workflow
- Feature branches per member
- Pull request reviews
- Main branch protected

---

## Notes

- This allocation can be adjusted based on team skills and preferences
- Members should be flexible to help others when needed
- Regular code reviews ensure quality and knowledge sharing
- Documentation should be updated as code changes
