//
//  ViewController.swift
//  Maze
//
//  Created by 小野　櫻 on 2018/04/13.
//  Copyright © 2018年 小野　櫻. All rights reserved.
//

    import UIKit
    import CoreMotion
    
    class ViewController: UIViewController {
        
        var playerView: UIView!
        var playerMotionManager: CMMotionManager!
        var speedX = 0.0
        var speedY = 0.0
        
        //画面サイズの取得
        var screenSize = UIScreen.main.bounds.size
        
        //迷路のマップを表した配列
        let maze = [
            [1, 0, 0, 0, 1, 0],
            [1, 0, 1, 0, 1, 0],
            [3, 0, 1, 0, 1, 0],
            [1, 1, 1, 0, 0, 0],
            [1, 0, 0, 1, 1, 0],
            [0, 0, 1, 0, 0, 0],
            [0, 1, 1, 0, 1, 0],
            [0, 0, 0, 0, 1, 1],
            [0, 1, 1, 0, 0, 0],
            [0, 0, 1, 1, 1, 2]
        ]
        
        var startView: UIView!
        var goalView: UIView!
        
        //wallViewのフレームを入れておく配列
        var wallRectArray: [CGRect] = [CGRect]()
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            self.screenSize = self.view.frame.size
            
            let cellWidth = screenSize.width / CGFloat(maze[0].count)
            let cellHeight = screenSize.height / CGFloat(maze.count)
            
            let cellOffSetX = screenSize.width / CGFloat(maze[0].count*2)
            let cellOffSetY = screenSize.height / CGFloat(maze.count*2)
            
            for y in 0..<maze.count {
                for x in 0..<maze[y].count {
                    switch maze[y][x] {
                        
                    case 1://当たるとゲームオーバーになるマス
                        let wallView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offSetX: cellOffSetX, offSetY: cellOffSetY)
                        wallView.backgroundColor = UIColor.black
                        self.view.addSubview(wallView)
                        self.wallRectArray.append(wallView.frame)
                        
                    case 2://スタート地点
                        startView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offSetX: cellOffSetX, offSetY: cellOffSetY)
                        startView.backgroundColor = UIColor.green
                        self.view.addSubview(startView)
                        
                    case 3://ゴール地点
                        goalView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offSetX: cellOffSetX, offSetY: cellOffSetY)
                        goalView.backgroundColor = UIColor.red
                        self.view.addSubview(goalView)
                    default:
                        break
                    }
                }
            }
            
            //playerViewの生成
            playerView = UIView(frame: CGRect(x: 0, y: 0, width: cellWidth / 6, height: cellHeight / 6))
            playerView.center = startView.center
            playerView.backgroundColor = UIColor.gray
            self.view.addSubview(playerView)
            
            //MotionManagerを生成
            playerMotionManager = CMMotionManager()
            playerMotionManager.accelerometerUpdateInterval = 0.02
            
            self.StartAccelerometer()
            
        }
        
        override func didReceiveMemoryWarning() {
            super.didReceiveMemoryWarning()
            // Dispose of any resources that can be recreated.
        }
        
        func createView(x: Int, y: Int, width: CGFloat, height: CGFloat, offSetX: CGFloat, offSetY: CGFloat) -> UIView {
            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            
            let view = UIView(frame: rect)
            
            let center = CGPoint(x: offSetX + CGFloat(x)*width, y: offSetY + CGFloat(y)*height)
            
            view.center = center
            
            return view
        }
        
        func StartAccelerometer() {
            //加速度を取得する
            let handler: CMAccelerometerHandler = { (CMAccelerometerData: CMAccelerometerData?, error: Error?) -> Void in
                self.speedX += CMAccelerometerData!.acceleration.x
                self.speedY += CMAccelerometerData!.acceleration.y
                
                //プレイヤーの中心位置を設定
                var posX = self.playerView.center.x + CGFloat(self.speedX) / 5
                var posY = self.playerView.center.y - CGFloat(self.speedY) / 5
                
                //画面上からプレーヤーがはみ出しそうだったらpostX/postY を修正
                if posX <= self.playerView.frame.width / 2 {
                    self.speedX = 0
                    posX = self.playerView.frame.width / 2
                }
                if posY <= self.playerView.frame.height / 2 {
                    self.speedY = 0
                    posY = self.playerView.frame.height / 2
                }
                if posX >= self.screenSize.width - self.playerView.frame.width / 2 {
                    self.speedX = 0
                    posX = self.screenSize.width - self.playerView.frame.width / 2
                }
                if posY >= self.screenSize.height - self.playerView.frame.height / 2 {
                    self.speedY = 0
                    posY = self.screenSize.height - self.playerView.frame.height / 2
                }
                
                //壁とボールがぶつかったかどうか
                for wallRect in self.wallRectArray {
                    if wallRect.intersects(self.playerView.frame) {
                        print("Game Over")
                        
                        self.gameCheck(result: "Game Over", message: "壁に当たりました")
                        
                        return
                    }
                }
                
                if self.goalView.frame.intersects(self.playerView.frame) {
                    print("Clear")
                    
                    self.gameCheck(result: "clear", message: "クリアしました")
                    
                    return
                }
                self.playerView.center = CGPoint(x: posX, y: posY)
            }
            
            //加速度の開始
            playerMotionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: handler)
        }
        
        func gameCheck(result: String, message: String) {
            //加速度を止める
            if self.playerMotionManager.isAccelerometerActive {
                self.playerMotionManager.stopAccelerometerUpdates()
            }
            
            let alert = UIAlertController(title: result,
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "もう一度",
                                          style: .default,
                                          handler: { (action) in
                                            self.retry()
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
        
        func retry() {
            //プレイヤーの位置を初期化
            self.playerView.center = self.startView.center
            //加速度センサーを始める
            if !playerMotionManager.isAccelerometerActive {
                self.StartAccelerometer()
            }
            //スピードを初期化
            self.speedX = 0.0
            self.speedY = 0.0
            
        }
        
}

