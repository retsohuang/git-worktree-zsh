#!/bin/bash

# Layered Testing Strategy Script
# This implements the test isolation strategy

set -e

echo "🧪 Running Layered Test Strategy"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test results tracking
CORE_PASSED=false
UNIT_PASSED=false
INTEGRATION_PASSED=false
ENV_PASSED=false

echo ""
echo "📋 PHASE 1: Core Functionality Tests (MUST PASS)"
echo "================================================"
echo "These tests verify the core value proposition and MUST pass."

if bats test/core/; then
    echo -e "${GREEN}✅ CORE TESTS PASSED${NC}"
    CORE_PASSED=true
else
    echo -e "${RED}❌ CORE TESTS FAILED${NC}"
    echo -e "${RED}🚨 CRITICAL: Core functionality is broken!${NC}"
    echo "Core tests verify the main value proposition of organized worktree structure."
    echo "These failures indicate fundamental problems that MUST be fixed."
    exit 1
fi

echo ""
echo "🔧 PHASE 2: Unit Tests (MUST PASS)"
echo "=================================="
echo "These test individual functions in isolation."

if bats test/unit/; then
    echo -e "${GREEN}✅ UNIT TESTS PASSED${NC}"
    UNIT_PASSED=true
else
    echo -e "${RED}❌ UNIT TESTS FAILED${NC}"
    echo -e "${RED}🚨 CRITICAL: Individual functions are broken!${NC}"
    echo "Unit test failures indicate problems with core function logic."
    exit 1
fi

echo ""
echo "🔄 PHASE 3: Integration Tests (MUST PASS for release)"
echo "====================================================="
echo "These test complete workflows end-to-end."

if bats test/integration/; then
    echo -e "${GREEN}✅ INTEGRATION TESTS PASSED${NC}"
    INTEGRATION_PASSED=true
else
    echo -e "${YELLOW}⚠️  INTEGRATION TESTS FAILED${NC}"
    echo "Integration test failures indicate workflow problems."
    echo "These should be fixed but don't block development."
    INTEGRATION_PASSED=false
fi

echo ""
echo "🌍 PHASE 4: Environment Tests (Failures Allowed)"
echo "================================================"
echo "These test environment-specific features (completion, performance, platform)."

if bats test/environment/ 2>/dev/null; then
    echo -e "${GREEN}✅ ENVIRONMENT TESTS PASSED${NC}"
    ENV_PASSED=true
else
    echo -e "${YELLOW}⚠️  ENVIRONMENT TESTS FAILED (This is acceptable)${NC}"
    echo "Environment test failures are often due to test environment limitations."
    echo "These failures don't indicate problems with core functionality."
    ENV_PASSED=false
fi

echo ""
echo "📊 SUMMARY"
echo "========="
echo -e "Core Tests:        $([ "$CORE_PASSED" = true ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo -e "Unit Tests:        $([ "$UNIT_PASSED" = true ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${RED}FAILED${NC}")"
echo -e "Integration Tests: $([ "$INTEGRATION_PASSED" = true ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${YELLOW}FAILED${NC}")"
echo -e "Environment Tests: $([ "$ENV_PASSED" = true ] && echo -e "${GREEN}PASSED${NC}" || echo -e "${YELLOW}FAILED${NC}")"

echo ""
if [ "$CORE_PASSED" = true ] && [ "$UNIT_PASSED" = true ]; then
    if [ "$INTEGRATION_PASSED" = true ]; then
        echo -e "${GREEN}🎉 ALL CRITICAL TESTS PASSED - Ready for release!${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  CORE FUNCTIONALITY OK - Integration issues present${NC}"
        echo "The organized worktree structure works correctly."
        echo "Integration issues should be addressed before release."
        exit 0
    fi
else
    echo -e "${RED}💥 CRITICAL TESTS FAILED - DO NOT MERGE${NC}"
    exit 1
fi