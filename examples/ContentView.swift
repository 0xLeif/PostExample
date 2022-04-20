//
//  ContentView.swift
//  examples
//
//  Created by Leif on 4/19/22.
//

import SwiftUI


// MVVM

// Model
struct Post: Codable, Identifiable {
  let userId: Int
  let id: Int
  let title: String
  let body: String
}

class ContentViewModel: ObservableObject {
  enum Tab {
    case posts, favorites
  }
  
  @Published var allPosts: [Post] = []
  @Published var favoriteIDs: [Int] = []
  
  @Published var current: Tab = .posts
  
  var lastTimeFetched: Date?
  
  func load() {
    URLSession.shared
      .dataTask(
      with: URL(string: "https://jsonplaceholder.typicode.com/posts")!,
      completionHandler: { data, response, error in
        if let error = error {
          print(error)
          return
        }
        
        guard
          let data = data,
          let posts = try? JSONDecoder()
            .decode([Post].self, from: data)
        else {
          return
        }

        DispatchQueue.main.async {
          self.allPosts = posts
        }
        
        self.lastTimeFetched = Date()
      }
    )
    .resume()
  }
}

struct ContentView: View {
  @StateObject private var viewModel = ContentViewModel()
  
  var body: some View {
    TabView(selection: $viewModel.current) {
      PostsView(
        allPosts: viewModel.allPosts,
        favorites: $viewModel.favoriteIDs
      )
        .tag(ContentViewModel.Tab.posts)
        .tabItem {
          VStack {
            Image(systemName: "list.bullet")
            Text("Posts")
          }
        }
      
      FavoritesView(
        allPosts: viewModel.allPosts,
        favorites: $viewModel.favoriteIDs
      )
        .tag(ContentViewModel.Tab.favorites)
        .tabItem {
          VStack {
            Image(systemName: "star.circle")
            Text("Favorites")
          }
        }
    }
    .onAppear {
      viewModel.load()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

// MARK: - Views

struct PostsView: View {
  var allPosts: [Post]
  @Binding var favorites: [Int]
  
  var body: some View {
    List(allPosts) { post in
      Button(post.title) {
        if favorites.contains(post.id) {
          favorites.removeAll(where: { $0 == post.id })
        } else {
          favorites.append(post.id)
        }
      }
    }
  }
}


struct FavoritesView: View {
  var allPosts: [Post]
  @Binding var favorites: [Int]
  
  var body: some View {
    List(favorites, id: \.self) { favoritePostID in
      if let post = allPosts.first(where: { favoritePostID == $0.id }) {
        Button(post.title) {
          favorites.removeAll(where: { favoritePostID == $0 })
        }
      }
    }
  }
}
