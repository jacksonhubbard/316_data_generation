//
//  ViewController.swift
//  BooksToFirebase
//
//  Created by Jackson Hubbard on 10/31/20.
//  Copyright © 2020 Jackson Hubbard. All rights reserved.
//

import UIKit
import Firebase
import SwiftyJSON



// books need:
//    - book_uid (generate = doc title)
//    - isbn     (api)
//    - author   (api)
//    - condition (generate randomly)
//    - description (api)
//    - published date (api)
//    - title  (Api)
//
//
// users need:
//    - first_name (random api)
//    - last_name (random api)
//    - uid (gernate = doc title)
//    - location
//    - num_books_given
//    - num_books_received
//    - phone_number
//    -
//    -


class ViewController: UIViewController {

    let db = Firestore.firestore()

    
    struct Book {
        var isbn: String
        var author: String
        var description: String
        var published_date: String
        var title: String
        var image_link: String
    }
    var books = [Book]()
    var isbns = [String]()
    var count = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        to add book data
//        convertCSVIntoArray()
        
//        to add user data
//        addUsers()
        
//        deleteData()
        
//        editData()
        
        addReview()
    }

    func editData(){
        let queryRef = db.collection("Books").limit(to: 100).getDocuments() { (querySnapshot, err) in
          if let err = err {
            print("Error getting documents: \(err)")
          } else {
            
            var i = 0
            for document in querySnapshot!.documents {
                if i < 100 {
                    i += 1
                    let docData = document.data()
                    let bookUID = docData["book_UID"] as? String ?? "User not found"
                    
                    self.db.collection("Books").document(bookUID).updateData(["is_active": true]) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("is active updated!", i) }}
                }
            }
          }
        }
    }
    
    
    
    
    
    func convertCSVIntoArray() {

        //locate the file you want to use
//        guard let filepath = Bundle.main.path(forResource: "books", ofType: "csv") else {
        guard let filepath = Bundle.main.path(forResource: "book3", ofType: "csv") else {

            return
        }

        //convert that file into one long string
        var data = ""
        do {
            data = try String(contentsOfFile: filepath)
        } catch {
            print(error)
            return
        }

        //now split that string into an array of "rows" of data.  Each row is a string.
        var rows = data.components(separatedBy: "\n")
        var count = 0
        //now loop around each row, and split it into each of its columns
        for row in rows {
            count += 1
            let columns = row.components(separatedBy: ",")
            let currISBN = columns[0].filter { !$0.isWhitespace }
            print(currISBN)

            isbns.append(currISBN)
            
//            if (count > 200 && count<350) {
//            if (count <= 100) {
            if count > 350 {
                getBookInfo(isbn: currISBN)
            }
        }
//        print(isbns)
        print(isbns.count)
    }
    
    
    func deleteData() {
        let now = Date()
        
        let queryRef = db.collection("Books").whereField("date_posted", isDateInToday: now).getDocuments() { (querySnapshot, err) in
          if let err = err {
            print("Error getting documents: \(err)")
          } else {
            for document in querySnapshot!.documents {
              document.reference.delete()
            }
          }
        }
        

    }
   
    
    func getBookInfo(isbn: String) {

        let url = "https://www.googleapis.com/books/v1/volumes?q=isbn:" + isbn
        let bookUID = UUID().uuidString
        
        let session = URLSession(configuration: .default)
            
            session.dataTask(with: URL(string: url)!) { (data, _, err) in
                
                if err != nil{
                    
                    print((err?.localizedDescription)!)
                    return
                }
                
                let json = try! JSON(data: data!)
                
                if let items = json["items"].array {
                    for i in items{
                        
                        let id = i["id"].stringValue
                        
                        let title = i["volumeInfo"]["title"].stringValue
                        print(title)
                        let authors = i["volumeInfo"]["authors"].array
                        var author = "No Author Found"
                        if authors != nil {
                            author = authors![0].stringValue
                        }
                        
                        let pub_date = i["volumeInfo"]["publishedDate"].stringValue

//                        var author = authors[0].stringValue
                    
                        let description = i["volumeInfo"]["description"].stringValue
                        
                        let imurl = i["volumeInfo"]["imageLinks"]["thumbnail"].stringValue
                        
                        let conditions = ["Brand New", "Like New", "Gently Used", "Used", "Poor"]
                        let condition = conditions.randomElement()
                        
                        // for books
//                        let genres = ["Adventure", "Action", "Comedy", "Romance", "Childrens", "Sports"]
//                        let genre = genres.randomElement()
                        
                        // for textbooks
                        let categories = i["volumeInfo"]["categories"].array
                        var category = "No subject found"
                        if categories != nil {
                            category = categories![0].stringValue
                        }

                        
                        let now = Date()
                        let currDate = Timestamp(date: now)
                        DispatchQueue.main.async {
                            self.count += 1
                            print(self.count)
                            self.books.append(Book(isbn: isbn, author: author, description: description, published_date: pub_date, title: title, image_link: imurl))
                            
                            let docData: [String: Any] = [
                                "isbn": isbn,
                                "author": author,
                                "description": description,
                                "published_date": pub_date,
                                "title": title,
                                "image_link": imurl,
                                "book_UID": bookUID,
                                "condition": condition,
                                "is_active": false,
                                "date_posted": currDate,
                                "type": "book",
                                "genre": category
                            ]
                            self.db.collection("Books").document(bookUID).setData(docData) { err in
                                if let err = err {
                                    print("Error writing document: \(err)")
                                } else {
                                    print("Document successfully written!")
//                                    var random_prev_owners = [String]()
//
                                    let num_prev_owners = Int.random(in: 1...7)
                                    print("num prev owners", num_prev_owners)
//                                    for prev_owner in 1...num_prev_owners{
//                                        let random_num = Int.random(in: 1...200)
//
//                                        self.downloadUsers(random_num: random_num) { (user) in
//                                            random_prev_owners.append(user)
//                                            print(user)
//                                        }
//
//                                    }
                                    
                                    self.downloadUsersHelper(num: num_prev_owners) { (listUsers) in
                                        print("list users", listUsers)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 7) {
                                            // your code here
                                        print("in delay func")
                                        
                                        
                                        self.downloadCurrOwner { (currOwner) in
                                            
                                            self.db.collection("Books").document(bookUID).updateData(["previous_owners": listUsers]) { err in
                                            if let err = err {
                                                print("Error writing document: \(err)")
                                            } else {
                                                print("prev owners updated!") }}
                                            self.db.collection("Books").document(bookUID).updateData(["curr_owner": currOwner]) { err in
                                            if let err = err {
                                                print("Error writing document: \(err)")
                                            } else {
                                                print("curr owner updated!") }}
                                            
                                            //need to pass through listUsers and for each pair, write to transaction db
                                            for i in 0...(listUsers.count-1) {
                                                let prevOwner = listUsers[i]
                                                let newIndex = i + 1
                                                let now = Date()
                                                let currDate = Timestamp(date: now)
                                                
                                                if newIndex < listUsers.count-1 {
                                                    let newOwner = listUsers[i+1]
                                                    
                                                    let transactUID = UUID().uuidString
                                                    self.db.collection("Transactions").document(transactUID).setData(["book": bookUID,
                                                                                                                      "receiver": newOwner,
                                                                                                                      "seller": prevOwner,
                                                                                                                      "date": currDate
                                                    ]){ err in
                                                    if let err = err {
                                                        print("Error writing document: \(err)")
                                                    } else {
                                                        print("transact updated!") }}
                                                    
                                                    
                                                }
                                                else {
                                                    let transactUID = UUID().uuidString
                                                    self.db.collection("Transactions").document(transactUID).setData(["book": bookUID,
                                                                                                                      "receiver": currOwner,
                                                                                                                      "seller": prevOwner,
                                                                                                                      "date": currDate
                                                    ]){ err in
                                                    if let err = err {
                                                        print("Error writing document: \(err)")
                                                    } else {
                                                        print("transact updated!") }}
                                                }
                                            }
                                        }
                                    }
                                        
                                    }
//                                    print(random_prev_owners)
//                                    self.db.collection("Books").document(bookUID).updateData(["previous_owners": random_prev_owners])
                                }
                            }
                            
                            
                        }
                    }
                }
                
            }.resume()
        

    }
    
    func downloadUsersHelper(num:Int, completion: @escaping ([String]) -> Void) {
        var listUsers = [String]()
        var count = 0
        var random_num = Int.random(in: 1...500)
        self.downloadUsers(random_num: random_num) { (user) in
            listUsers.append(user)
            count+=1
            if count<num{
                random_num = Int.random(in: 1...500)
                self.downloadUsers(random_num: random_num) { (user) in
                    listUsers.append(user)
                    count+=1
                    if count<=num{
                        random_num = Int.random(in: 1...500)
                        self.downloadUsers(random_num: random_num) { (user) in
                            listUsers.append(user)
                            count+=1
                            if count<=num{
                                random_num = Int.random(in: 1...500)
                                self.downloadUsers(random_num: random_num) { (user) in
                                    listUsers.append(user)
                                    count+=1
                                    if count<=num{
                                        random_num = Int.random(in: 1...500)
                                        self.downloadUsers(random_num: random_num) { (user) in
                                            listUsers.append(user)
                                            count+=1
                                            if count<=num{
                                                random_num = Int.random(in: 1...500)
                                                self.downloadUsers(random_num: random_num) { (user) in
                                                    listUsers.append(user)
                                                    count+=1
                                                    if count<=num{
                                                        random_num = Int.random(in: 1...500)
                                                        self.downloadUsers(random_num: random_num) { (user) in
                                                            listUsers.append(user)
                                                            count+=1
                                                            
                                                            
                                                        }
                                                        
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    
                }
                
            }
            print("here4", listUsers)
            completion(listUsers)
        }
        
    }
    
    
    func downloadCurrOwner(completion: @escaping (String) -> Void) {
        
        let random_num = Int.random(in: 1...200)
        self.downloadUsers(random_num: random_num) { (user) in
            completion(user)
        }
       }
    
    
    func downloadUsers(random_num: Int, completion: @escaping (String) -> Void) {
        self.db.collection("UserData").whereField("index", isEqualTo: random_num)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        let docData = document.data()
                        let userID = docData["user_UID"] as? String ?? "User not found"
                        var currCountGiven = docData["num_books_given"] as? Int ?? 0
                        var currCountReceived = docData["num_books_received"] as? Int ?? 0
                        
                        currCountGiven += 1
                        currCountReceived += 1
                        
                        // need to increment books given here
                        self.db.collection("UserData").document(userID).updateData(["num_books_given": currCountGiven, "num_books_received": currCountReceived
                        ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                        }
                        
                        completion(userID)
                    }
                }
        }
    }
    
    
    func randomFakeFirstName() -> String {
        let firstNameList = ["Henry", "William", "Geoffrey", "Jim", "Yvonne", "Jamie", "Leticia", "Priscilla", "Sidney", "Nancy", "Edmund", "Bill", "Megan", "Jackson", "Jake", "Jack", "Collin", "Carson", "Maddie", "Steve", "Hailey", "John", "Kristin", "Erin", "Annie", "Harris", "Matthew", "Charlie", "Cameron", "Sophie", "Charlotte", "Grace"]
        let randomName = firstNameList.randomElement()!
        
        return randomName
    }

    func randomFakeLastName() -> String {
        let lastNameList = ["Pearson", "Adams", "Cole", "Francis", "Andrews", "Casey", "Gross", "Lane", "Thomas", "Patrick", "Strickland", "Nicolas", "Freeman", "Smith", "Walker", "Wilson", "Garrett", "Hall", "Johnson", "Jones", "Jordan", "Landon", "Lawrence", "Michael", "Parker", "Williams", "Scott"]
        let randomName = lastNameList.randomElement()!
        
        return randomName
    }
    
    func randomFakeLocation() -> String {
        let cityList = ["Durham, NC", "Chapel Hill, NC", "Raleigh, NC"]
        let randomCity = cityList.randomElement()!
        
        return randomCity
    }
    
    
    func randomFakeNumberHelper() -> String {
         var result = ""
         repeat {
             // Create a string with a random number 0...9999
             result = String(format:"%04d", arc4random_uniform(10000) )
         } while result.count < 4
         return result
    }
    
    func randomFakeNumber() -> String {
        let first3 = randomFakeNumberHelper().prefix(3)
        let middle = randomFakeNumberHelper()
        let last = randomFakeNumberHelper()
        let phone_num = first3 + "-" + middle + "-" + last
        return phone_num
    }


    func addUsers() {
        for i in 0...500{
            let firstName = randomFakeFirstName()
            let lastName = randomFakeLastName()
            let uid = UUID().uuidString
            let location = randomFakeLocation()
            let phone_number = randomFakeNumber()
            
            let currUserUID = UUID().uuidString
            let email = "testuser" + String(i) + "@gmail.com"
            
            let currUserData: [String: Any] = [
                "first_name": firstName,
                "last_name": lastName,
                "location": location,
                "num_books_given": 0,
                "num_books_received": 0,
                "phone_number": phone_number,
                "user_UID": currUserUID,
                "index": i,
                "email": email
            ]
            db.collection("UserData").document(currUserUID).setData(currUserData) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
            
        }
        
    }
    
    
    
    func randomReview() -> [String: String] {
            var ans = [String: String]()
            let reviewList = ["This book is so good!", "This book is incredible", "Best book I have ever read", "This book is average", "This book is so boring. I would not wish it upon my worst enemy"]
            let titleList = ["My favorite book ever!", "AMAZING", "READ THIS", "OK Book", "Do not buy this book"]
            
            let count = reviewList.count
            let randomIndex = Int.random(in: 0..<count)
            let randomReview = reviewList[randomIndex]
            let randomTitle = titleList[randomIndex]
            
            var stars = 0
            if randomIndex <= 2{
                stars = Int.random(in: 4..<6)
            }
            else if randomIndex == 3 {
                stars = Int.random(in: 2..<4)
            }
            else {
                stars = 1
            }
            
            
            let startList = ["1", "2", "3", "4", "5"]
            
            ans["review"] = randomReview
            ans["title"] = randomTitle
            ans["stars"] = String(stars)

            
            return ans
        }
        
        
        func addReview(){
            let queryRef = db.collection("Books").getDocuments() { (querySnapshot, err) in
              if let err = err {
                print("Error getting documents: \(err)")
              } else {
                
                for document in querySnapshot!.documents {
                    let docData = document.data()
                    let bookUID = docData["book_UID"] as? String ?? "User not found"
                    let curr_owner = docData["curr_owner"] as? String ?? "User not found"

                    let prev_owners = docData["previous_owners"] as? [String]
                    let prev_owner = prev_owners?[0]
                    
                    let review1UID = UUID().uuidString
                    let review2UID = UUID().uuidString

                    
                    
                    let review1Data = self.randomReview()
                    let review1Title = review1Data["title"]
                    let review1Review = review1Data["review"]
                    let review1Stars = review1Data["stars"]
                    
                    let review2Data = self.randomReview()
                    let review2Title = review2Data["title"]
                    let review2Review = review2Data["review"]
                    let review2Stars = review2Data["stars"]
                    
                    self.db.collection("Books").document(bookUID).collection("Reviews").document(review1UID).setData([ "author": prev_owner,
                                                                                                                       "title": review1Title,
                                                                                                                       "numStars": review1Stars,
                                                                                                                       "review": review1Review,
                                                                                                                       "date_posted": "11/14/2020"
                    ]) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("review1 successfully written!")
                        }}
                    
    //                self.db.collection("Books").document(bookUID).collection("Reviews").document(review2UID).setData([ "author": curr_owner,
    //                                                                                                                   "title": review2Title,
    //                                                                                                                   "numStars": review2Stars,
    //                                                                                                                   "review": review2Review,
    //                                                                                                                   "date_posted": "11/15/2020"
    //                ]) { err in
    //                if let err = err {
    //                    print("Error writing document: \(err)")
    //                } else {
    //                    print("review2 successfully written!")
    //                    }}

                        
                
                    
                }
              }
            }
        }
    
}

extension CollectionReference {
    func whereField(_ field: String, isDateInToday value: Date) -> Query {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: value)
        guard
            let start = Calendar.current.date(from: components),
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start)
        else {
            fatalError("Could not find start date or calculate end date.")
        }
        return whereField(field, isGreaterThan: start).whereField(field, isLessThan: end)
    }
}

    

