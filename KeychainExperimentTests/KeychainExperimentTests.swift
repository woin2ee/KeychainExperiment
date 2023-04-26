//
//  KeychainExperimentTests.swift
//  KeychainExperimentTests
//
//  Created by Jaewon Yun on 2023/03/20.
//

import XCTest
@testable import KeychainExperiment

final class KeychainExperimentTests: XCTestCase {

    override func setUp() {
        super.setUp()
        deleteAllInDefaultClass()
    }
    
    override func tearDown() {
        super.tearDown()
        deleteAllInDefaultClass()
    }
    
    // MARK: Save
    
    func testSaveItemWhenExistNilAttribute() {
        // Arrange
        let saveQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                    kSecAttrService: defaultService as Any,
                                    kSecAttrAccount: defaultAccount1 as Any,
                                      kSecAttrLabel: Optional<String>.none as Any, // set nil
                                      kSecValueData: defaultPasswordData1 as Any]
        
        // Act
        let status = SecItemAdd(saveQuery as CFDictionary, nil)
        
        // Assert
        if status == errSecSuccess {
            XCTFail("저장 실패가 예상됐으나 성공함.")
        } else {
            XCTAssert(true)
            XCTAssertEqual(status, errSecParam)
        }
    }
    
    func testSaveInteger() {
        // Arrange
        var number = 1111
        let numberData = Data.init(bytes: &number, count: MemoryLayout.size(ofValue: number))
        let saveQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                    kSecAttrService: defaultService as Any,
                                    kSecAttrAccount: defaultAccount1 as Any,
                                      kSecValueData: numberData]
        let searchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                      kSecAttrService: defaultService as Any,
                                      kSecAttrAccount: defaultAccount1 as Any,
                                       kSecReturnData: true]
        var numberResult: AnyObject? = nil
        
        // Act
        let status = SecItemAdd(saveQuery as CFDictionary, nil)
        if status != errSecSuccess {
            let errorMessage = SecCopyErrorMessageString(status, nil)
            XCTFail("저장 실패. \(errorMessage!)")
        }
        
        // Assert
        XCTAssertEqual(SecItemCopyMatching(searchQuery as CFDictionary, &numberResult), errSecSuccess)
        XCTAssertEqual(numberResult as? Data, numberData)
    }
    
    // MARK: Search
    
    func testItemSearch() {
        // Arrange
        prepareDefaultItem1()
        
        // Act
        let result = searchDefaultItem1()
        
        // Assert
        XCTAssertEqual(result as? Data, defaultPasswordData1)
    }
    
    func testSearchAllItemsWhenSavedTwoItems() {
        // Arrange default Items
        prepareDefaultItem1()
        prepareDefaultItem2()
        let item1 = searchDefaultItem1()
        let item2 = searchDefaultItem2()
        XCTAssertNotNil(item1)
        XCTAssertNotNil(item2)
        
        // Arrange query
        let multiSearchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                           kSecAttrService: defaultService as Any,
                                            kSecMatchLimit: kSecMatchLimitAll,
                                            kSecReturnData: true]
        
        // Act
        var result: CFTypeRef?
        let status = SecItemCopyMatching(multiSearchQuery as CFDictionary, &result)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            XCTFail("검색 실패. \(errorMessage!)")
        }
        
        // Assert
        let maybeArrayTypeID = CFGetTypeID(result)
        XCTAssertEqual(maybeArrayTypeID, CFArrayGetTypeID())
        let resultArray = result as! CFArray
        XCTAssertEqual(CFArrayGetCount(resultArray), 2)
        
        let item1Pointer = CFArrayGetValueAtIndex(resultArray, 0)
        let maybePasswordData1 = unsafeBitCast(item1Pointer, to: CFData.self)
        XCTAssertEqual(maybePasswordData1 as Data, defaultPasswordData1)
        
        let item2Pointer = CFArrayGetValueAtIndex(resultArray, 1)
        let maybePasswordData2 = unsafeBitCast(item2Pointer, to: CFData.self)
        XCTAssertEqual(maybePasswordData2 as Data, defaultPasswordData2)
    }
    
    func testSearchItemWhenAttributeSetToOptional() {
        // Arrange
        let saveQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                    kSecAttrService: defaultService as Any,
                                    kSecAttrAccount: Optional.some(defaultAccount1) as Any, // optional attr
                                      kSecValueData: Optional.some(defaultPasswordData1) as Any] // optional data
        let searchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                      kSecAttrService: defaultService as Any,
                                      kSecAttrAccount: defaultAccount1 as Any, // non optional attr
                                       kSecReturnData: true]
        var result: AnyObject?
        
        // Act
        if SecItemAdd(saveQuery as CFDictionary, nil) != errSecSuccess {
            XCTFail("저장 실패.")
        }
        let status = SecItemCopyMatching(searchQuery as CFDictionary, &result)
        
        // Assert
        if status != errSecSuccess {
            let errorMessage = SecCopyErrorMessageString(status, nil)
            XCTFail("검색 실패. \(errorMessage!)")
        }
        XCTAssertEqual(result as? Data, defaultPasswordData1)
    }
    
    func testSearchItemWhenExistNilAttribute() {
        // Arrange
        prepareDefaultItem1() // Only One item
        let searchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                      kSecAttrService: defaultService as Any,
                                      kSecAttrAccount: Optional<Any>.none as Any, // nil attr (success even if not exist)
                                       kSecReturnData: true]
        var result: AnyObject? = nil
        
        // Act
        let status = SecItemCopyMatching(searchQuery as CFDictionary, &result)
        
        // Assert
        XCTAssertEqual(status, errSecParam)
        XCTAssertNil(result)
    }
    
    // MARK: Delete
    
    func testDeleteAll() {
        // Arrange
        prepareDefaultItem1()
        let result = searchDefaultItem1()
        XCTAssertNotNil(result)
        
        // Act
        deleteAllInDefaultClass()
        
        // Assert
        let maybeNilResult = searchDefaultItem1()
        XCTAssertNil(maybeNilResult)
    }
    
    func testDeleteWhenNoItem() {
        // Arrange
        let query: [CFString: Any] = [kSecClass: defaultClass as Any,
                                kSecAttrService: defaultService as Any,
                                kSecAttrAccount: defaultAccount1 as Any,
                                 kSecReturnData: true]
        var result: CFTypeRef?
        
        // Act
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Assert
        XCTAssertNil(result)
        XCTAssertEqual(status, errSecItemNotFound)
    }
    
    // MARK: Update
    
    func testUpdateDataOfItem() {
        // Arrange default item
        prepareDefaultItem1()
        let result = searchDefaultItem1()
        XCTAssertEqual(result as? Data, defaultPasswordData1)
        
        // Arrange queries
        let defaultItemSearchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                                 kSecAttrService: defaultService as Any,
                                                 kSecAttrAccount: defaultAccount1 as Any]
        let newPassword: String! = "5678"
        let newPasswordData: Data! = newPassword.data(using: .utf8)
        let attributesToUpdate: [CFString: Any] = [kSecValueData: newPasswordData as Any]
        
        // Act
        let status = SecItemUpdate(defaultItemSearchQuery as CFDictionary, attributesToUpdate as CFDictionary)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            XCTFail("업데이트 실패. \(errorMessage!)")
        }
        
        // Assert
        let updatedResult = searchDefaultItem1()
        XCTAssertEqual(updatedResult as? Data, newPasswordData)
    }
    
    func testUpdateAccountAndDataOfItemWhenSavedOneItem() {
        // Arrange default Item
        prepareDefaultItem1()
        let result = searchDefaultItem1()
        XCTAssertEqual(result as? Data, defaultPasswordData1)

        // Arrange queries
        let defaultItemSearchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                                 kSecAttrService: defaultService as Any,
                                                 kSecAttrAccount: defaultAccount1 as Any]
        let newAccount: String! = "Hong"
        let newPasswordData: Data! = "5678".data(using: .utf8)
        let attributesToUpdate: [CFString: Any] = [kSecAttrAccount: newAccount as Any,
                                                     kSecValueData: newPasswordData as Any]
        let updatedItemSearchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                                 kSecAttrService: defaultService as Any,
                                                 kSecAttrAccount: newAccount as Any,
                                            kSecReturnAttributes: true,
                                                  kSecReturnData: true]
        
        // Act
        let status = SecItemUpdate(defaultItemSearchQuery as CFDictionary, attributesToUpdate as CFDictionary)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            XCTFail("업데이트 실패. \(errorMessage!)")
        }

        // Assert
        var updatedResult: CFTypeRef?
        let statusForSearchUpdatedItem = SecItemCopyMatching(updatedItemSearchQuery as CFDictionary, &updatedResult)
        let errorMessageForSearchUpdatedItem = SecCopyErrorMessageString(statusForSearchUpdatedItem, nil) as? String
        if statusForSearchUpdatedItem != errSecSuccess {
            XCTFail("검색 실패. \(errorMessageForSearchUpdatedItem!)")
        }
        guard let updatedAttributes = updatedResult as? [CFString: Any],
              let updatedAccount = updatedAttributes[kSecAttrAccount] as? String,
              let updatedData = updatedAttributes[kSecValueData] as? Data
        else {
            XCTFail("Account, Data 속성 추출 실패.")
            return
        }
        XCTAssertEqual(updatedAccount, newAccount)
        XCTAssertEqual(updatedData, newPasswordData)
    }
    
    func testUpdateAccountAndDataOfSpecificItemWhenSavedTwoItems() {
        // Arrange default Items
        prepareDefaultItem1()
        prepareDefaultItem2()
        let item1 = searchDefaultItem1()
        let item2 = searchDefaultItem2()
        XCTAssertNotNil(item1)
        XCTAssertNotNil(item2)

        // Arrange queries
        let defaultItem2SearchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                                 kSecAttrService: defaultService as Any,
                                                 kSecAttrAccount: defaultAccount2 as Any]
        let newAccount: String! = "Hong"
        let newPasswordData: Data! = "5678".data(using: .utf8)
        let attributesToUpdate: [CFString: Any] = [kSecAttrAccount: newAccount as Any,
                                                     kSecValueData: newPasswordData as Any]
        let updatedItemSearchQuery: [CFString: Any] = [kSecClass: defaultClass as Any,
                                                 kSecAttrService: defaultService as Any,
                                                 kSecAttrAccount: newAccount as Any,
                                            kSecReturnAttributes: true,
                                                  kSecReturnData: true]
        
        // Act
        let status = SecItemUpdate(defaultItem2SearchQuery as CFDictionary, attributesToUpdate as CFDictionary)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            XCTFail("업데이트 실패. \(errorMessage!)")
        }

        // Assert
        var updatedResult: CFTypeRef?
        let statusForSearchUpdatedItem = SecItemCopyMatching(updatedItemSearchQuery as CFDictionary, &updatedResult)
        let errorMessageForSearchUpdatedItem = SecCopyErrorMessageString(statusForSearchUpdatedItem, nil) as? String
        if statusForSearchUpdatedItem != errSecSuccess {
            XCTFail("검색 실패. \(errorMessageForSearchUpdatedItem!)")
        }
        guard let updatedAttributes = updatedResult as? [CFString: Any],
              let updatedAccount = updatedAttributes[kSecAttrAccount] as? String,
              let updatedData = updatedAttributes[kSecValueData] as? Data
        else {
            XCTFail("Account, Data 속성 추출 실패.")
            return
        }
        XCTAssertEqual(updatedAccount, newAccount)
        XCTAssertEqual(updatedData, newPasswordData)
        
        let maybeExist = searchDefaultItem1()
        let maybeNotExist = searchDefaultItem2()
        XCTAssertNotNil(maybeExist)
        XCTAssertNil(maybeNotExist)
    }
}

// MARK: - Private methods

private extension KeychainExperimentTests {
    
    var defaultClass: CFString! { kSecClassGenericPassword }
    var defaultService: String! { Bundle.main.bundleIdentifier }
    var defaultAccount1: String! { "Kim" }
    var defaultAccount2: String! { "Kim2" }
    var defaultPassword1: String! { "password" }
    var defaultPassword2: String! { "password2" }
    var defaultPasswordData1: Data! { defaultPassword1.data(using: .utf8)! }
    var defaultPasswordData2: Data! { defaultPassword2.data(using: .utf8)! }
    
    func prepareDefaultItem1() {
        let query: [CFString: Any] = [kSecClass: defaultClass as Any,
                                    kSecAttrService: defaultService as Any,
                                    kSecAttrAccount: defaultAccount1 as Any,
                                      kSecValueData: defaultPasswordData1 as Any]
        let status = SecItemAdd(query as CFDictionary, nil)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            debugPrint("저장 실패. \(#function) \(errorMessage!)")
        }
    }
    
    func prepareDefaultItem2() {
        let query: [CFString: Any] = [kSecClass: defaultClass as Any,
                                    kSecAttrService: defaultService as Any,
                                    kSecAttrAccount: defaultAccount2 as Any,
                                      kSecValueData: defaultPasswordData2 as Any]
        let status = SecItemAdd(query as CFDictionary, nil)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            debugPrint("저장 실패. \(#function) \(errorMessage!)")
        }
    }
    
    func searchDefaultItem1() -> CFTypeRef? {
        let query: [CFString: Any] = [kSecClass: defaultClass as Any,
                                kSecAttrService: defaultService as Any,
                                kSecAttrAccount: defaultAccount1 as Any,
                                 kSecReturnData: true]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            debugPrint("검색 실패. \(#function) \(errorMessage!)")
        }
        return result
    }
    
    func searchDefaultItem2() -> CFTypeRef? {
        let query: [CFString: Any] = [kSecClass: defaultClass as Any,
                                kSecAttrService: defaultService as Any,
                                kSecAttrAccount: defaultAccount2 as Any,
                                 kSecReturnData: true]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            debugPrint("검색 실패. \(#function) \(errorMessage!)")
        }
        return result
    }
    
    func search(byQuery query: [CFString: Any]) -> CFTypeRef? {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let errorMessage = SecCopyErrorMessageString(status, nil) as? String
        if status != errSecSuccess {
            debugPrint("검색 실패. \(#function) \(errorMessage!)")
        }
        return result
    }
    
    func deleteAllInDefaultClass() {
        let query: [CFString: Any] = [kSecClass: defaultClass as Any]
        SecItemDelete(query as CFDictionary)
    }
}
