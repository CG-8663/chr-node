#!/usr/bin/env node

// Test script for the chr-node installation server
const http = require('http');

const BASE_URL = 'http://localhost:3333';

console.log('🧪 Testing chr-node Installation Server');
console.log('=======================================');
console.log('');

async function testEndpoint(path, description) {
    return new Promise((resolve) => {
        const startTime = Date.now();
        
        http.get(`${BASE_URL}${path}`, (res) => {
            let data = '';
            
            res.on('data', (chunk) => {
                data += chunk;
            });
            
            res.on('end', () => {
                const duration = Date.now() - startTime;
                const status = res.statusCode;
                
                if (status === 200) {
                    console.log(`✅ ${description}: ${status} (${duration}ms)`);
                    resolve({ success: true, status, duration, data });
                } else {
                    console.log(`❌ ${description}: ${status} (${duration}ms)`);
                    resolve({ success: false, status, duration, data });
                }
            });
            
        }).on('error', (err) => {
            const duration = Date.now() - startTime;
            console.log(`❌ ${description}: Connection failed (${duration}ms) - ${err.message}`);
            resolve({ success: false, error: err.message, duration });
        });
    });
}

async function runTests() {
    console.log(`Testing server at: ${BASE_URL}`);
    console.log('');
    
    const tests = [
        { path: '/', description: 'Landing page' },
        { path: '/install', description: 'Installation script' },
        { path: '/api/health', description: 'Health check' },
        { path: '/api/stats', description: 'Statistics API' },
    ];
    
    const results = [];
    
    for (const test of tests) {
        const result = await testEndpoint(test.path, test.description);
        results.push({ ...test, ...result });
    }
    
    console.log('');
    console.log('📊 Test Results Summary');
    console.log('=======================');
    
    const passed = results.filter(r => r.success).length;
    const total = results.length;
    
    console.log(`Tests passed: ${passed}/${total}`);
    
    if (passed === total) {
        console.log('🎉 All tests passed! Server is working correctly.');
        
        console.log('');
        console.log('🌐 Server URLs:');
        console.log(`   Landing page: ${BASE_URL}`);
        console.log(`   Install script: ${BASE_URL}/install`);
        console.log(`   Health check: ${BASE_URL}/api/health`);
        console.log(`   Statistics: ${BASE_URL}/api/stats`);
        
        console.log('');
        console.log('📱 Test installation command:');
        console.log(`   curl -L ${BASE_URL}/install | bash`);
        
    } else {
        console.log('❌ Some tests failed. Check server status.');
        
        const failed = results.filter(r => !r.success);
        console.log('');
        console.log('Failed tests:');
        failed.forEach(test => {
            console.log(`   ${test.description}: ${test.error || `HTTP ${test.status}`}`);
        });
    }
    
    console.log('');
    console.log('💡 Tips:');
    console.log('   - Make sure server is running: npm start');
    console.log('   - Check port 3333 is available');
    console.log('   - Test QR code functionality in browser');
    console.log('   - Verify installation script downloads correctly');
}

// Check if server is specified as argument
if (process.argv[2]) {
    const customUrl = process.argv[2];
    BASE_URL = customUrl.startsWith('http') ? customUrl : `http://${customUrl}`;
    console.log(`Using custom server URL: ${BASE_URL}`);
    console.log('');
}

runTests().catch(console.error);