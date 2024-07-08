import UIKit

class MovieViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
{
    @IBOutlet weak var tableView: UITableView!
        
    var movies: [Movie] = []
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        fetchMovies { [weak self] movies, error in
            DispatchQueue.main.async
            {
                if let movies = movies
                {
                    if movies.isEmpty
                    {
                        // Display a message for no data
                        self?.displayErrorMessage("No movies available.")
                    } else {
                        self?.movies = movies
                        self?.tableView.reloadData()
                    }
                } else if let error = error {
                    if let urlError = error as? URLError, urlError.code == .timedOut
                    {
                        // Handle timeout error
                        self?.displayErrorMessage("Request timed out.")
                    } else {
                        // Handle other errors
                        self?.displayErrorMessage(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func displayErrorMessage(_ message: String)
    {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func fetchMovies(completion: @escaping ([Movie]?, Error?) -> Void)
    {
        guard let url = URL(string: "https://mdev1004-ice-api.onrender.com/api/movie/list") else
        {
            print("URL Error")
            completion(nil, nil) // Handle URL error
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("Network Error")
                completion(nil, error) // Handle network error
                return
            }

            guard let data = data else {
                print("Empty Response")
                completion(nil, nil) // Handle empty response
                return
            }
            
            // Response
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let success = json?["success"] as? Bool, success == true
                {
                    if let moviesData = json?["data"] as? [[String: Any]]
                    {
                        let movies = try JSONSerialization.data(withJSONObject: moviesData, options: [])
                        let decodedMovies = try JSONDecoder().decode([Movie].self, from: movies)
                        completion(decodedMovies, nil) // success
                    }
                    else
                    {
                        print("Missing 'data' field in JSON response")
                        completion(nil, nil) // Handle missing data field
                    }
                }
                else
                {
                    print("API Rrequet unsuccessful")
                    let errorMessage = json?["msg"] as? String ?? "Uknown Error"
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    completion(nil, error)
                }
                
            } catch {
                print("Error Decoding JSON Data")
                completion(nil, error) // Handle JSON decoding error
            }
        }.resume()
    }


    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return movies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MovieTableViewCell
                        
                
        let movie = movies[indexPath.row]
                        
        cell.titleLabel?.text = movie.title
        cell.studiLabel?.text = movie.studio
        cell.ratingLabel?.text = "\(movie.criticsRating ?? 0.0)"
                
        // Set the background color of criticsRatingLabel based on the rating
        let rating = movie.criticsRating


        if let rating = rating {
            if rating > 7 {
                cell.ratingLabel.backgroundColor = UIColor.green
                cell.ratingLabel.textColor = UIColor.black
            } else if rating > 5 {
                cell.ratingLabel.backgroundColor = UIColor.yellow
                cell.ratingLabel.textColor = UIColor.black
            } else {
                cell.ratingLabel.backgroundColor = UIColor.red
                cell.ratingLabel.textColor = UIColor.white
            }
        } else {
            // Handle the case where rating is nil, if needed
            cell.ratingLabel.backgroundColor = UIColor.gray
            cell.ratingLabel.textColor = UIColor.white
            cell.ratingLabel.text = "N/A"
        }
        
        
        return cell
    }
}
