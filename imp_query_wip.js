// db.subs.aggregate([
// // stage 1 : check if a document has subscriptions array exists and not null
// {
//   '$match': {'subscriptions': {'$elemMatch': {'$exists': true}}}
// },
// 
// // stage 2
// {
//    '$project': { count: { '$size':"$subscriptions" }}
// },
// {
//    '$match': {'count': {'$gt': 4}}
// }
// 
// ]);

db.subs.aggregate([
    {
        '$match': { 'subscriptions.4': {'$exists': true}}
    },
    
//     stage 2: add a count field nested array document if it is a duplicate
    {
        '$unwind': '$subscriptions'
    },
    
    // stage 3: 
    {
    '$group': {

                    '_id': {
                       'vin': '$vin',
                       'productCode': '$subscriptions.productCode',
                       'status': '$subscriptions.status',
                       'type': '$subscriptions.type'
                     },
                    'count': {'$sum': 1},
//                     'ids': {'$push': '$vin'}
                }, 
    },
//     stage 4: 
    {
       '$match': {'count': {'$gte': 2}}
    }
    
//     // stage 5:
//     {
//         '$group': {  
//             '$_id': '$_id.vin',
//             'subscriptions': {  '$push': '_id. }
//          }
//     }
]);


// This is to find all docs with size is with in given range, ex : [2, 3]
// db.subs.aggregate([
//     {
//         '$match': {    '$or':[ {'subscriptions': {'$exists': true, '$size': 2}}, {'subscriptions': {'$exists': true, '$size': 3}} ]    }
//     }
// ]);


// this is for getting those docs with nested array size != n
// db.subs.find({"subscriptions":{"$exists":true, "$ne":[], "$not":{"$size":5}}});



// -------------------------------------------------------------------------

db.subs.aggregate([
    {
        '$match': { 'subscriptions.2': {'$exists': true}}
    },
    
//     stage 2: add a count field nested array document if it is a duplicate
    {
        '$unwind': '$subscriptions'
    },
    
    // stage 3: 
    {
    '$group': {

                    '_id': {
                       'vin': '$vin',
                       'productCode': '$subscriptions.productCode',
                       'status': '$subscriptions.status',
                       'type': '$subscriptions.type'
                     },
                    'count': {'$sum': 1},
                    'user' :{'$first': '$$ROOT'}, 
                }
    },
    // stage 4:
    {
       '$replaceRoot': {
            'newRoot': { '$mergeObjects': [{ 'count': '$count' }, '$user'] }
        }
    },
    // stage: 5
    {
           "$group": {
               "_id": "$vin",
               'subscriptions': {'$push': '$subscriptions'},
           }
    },
    // stage: 6
    {
           "$addFields": {
               "vin": "$_id",
           }
    },
]);

//----------------------------------------------------------------------
// db.subs.aggregate([
// // stage 1 : check if a document has subscriptions array exists and not null
// {
//   '$match': {'subscriptions': {'$elemMatch': {'$exists': true}}}
// },
// 
// // stage 2
// {
//    '$project': { count: { '$size':"$subscriptions" }}
// },
// {
//    '$match': {'count': {'$gt': 4}}
// }
// 
// ]);

db.subs.aggregate([
    {
        '$match': { 'subscriptions.2': {'$exists': true}}
    },
    
//     stage 2: add a count field nested array document if it is a duplicate
    {
        '$unwind': '$subscriptions'
    },
    
    // stage 3: 
    {
    '$group': {

                    '_id': {
                       'vin': '$vin',
                       'productCode': '$subscriptions.productCode',
                       'status': '$subscriptions.status',
                       'type': '$subscriptions.type'
                     },
//                     '_id': { '$concat': ['$vin', '$subscriptions.productCode', '$subscriptions.status', '$subscriptions.type'] },
                    'count': {'$sum': 1},
     
//                     'subscriptions': {'$push': '$subscriptions'},
                    'user' :{'$first': '$$ROOT'},
                    
//                     'mergedSubscriptions': { '$mergeObjects': "$subscriptions" } 
                }
    },
        {
            '$replaceRoot': {
                    'newRoot': { '$mergeObjects': [{ 'count': '$count' }, '$user'] }
            }
    },
    
    
    {
           "$group": {
               "_id": "$vin",
               'subscriptions': {'$push': '$subscriptions'},
           }
     }
    
//     {
//         '$addFields': {
//             'vin': '$_id.vin',
//             'subs': { '$arrayElemAt': [ "$subscriptions", 0 ] }
//         }
//     },
//      {
//         "$project": {
//             'vin': '_id.vin',
//             "subscriptions": {
//                 "$reduce": {
//                     "input": "$subscriptions",
//                     "initialValue": [],
//                     "in": { "$setUnion": ["$$value", "$$this"] }
//                 }
//             }
//         }
//     },
//     
//     {
//             '$replaceRoot': {
//                     'newRoot': { '$mergeObjects': [{ 'count': '$count' }, '$user.'] }
//             }
//     },
  
   // stage
//     {
//             '$replaceRoot': {
//                     'newRoot': { '$mergeObjects': [{ 'count': '$count' }, '$user'] }
//             }
//     },
    
    
//     stage 4: 
//     {
//        '$match': {'count': {'$gte': 1}}
//     },
//         {
//            "$group": {
//                "_id": "$_id.vin"
//            }
//         }
    
]);


// This is to find all docs with size is with in given range, ex : [2, 3]
// db.subs.aggregate([
//     {
//         '$match': {    '$or':[ {'subscriptions': {'$exists': true, '$size': 2}}, {'subscriptions': {'$exists': true, '$size': 3}} ]    }
//     }
// ]);


// this is for getting those docs with nested array size != n
// db.subs.find({"subscriptions":{"$exists":true, "$ne":[], "$not":{"$size":5}}});