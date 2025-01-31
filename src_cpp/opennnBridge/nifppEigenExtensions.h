/*****************************************************
 * Authors: David Leon & Evgeni Andrachnic
 * 29/10/2021
 * 
 * @copyright Copyright (c) 2021 Nerlnet
 *****************************************************/ 


#pragma once 

#include "nifpp.h"
#include "../opennn/opennn/opennn.h"


#define MAX_SUPPORTED_DIMS 3

#define EXCEPTION_STR_INVALID_ERL_TENSOR "Invalid Erlang Tensor (List)"

namespace nifpp
{
    // Float number conversions
    inline int get(ErlNifEnv *env, ERL_NIF_TERM term, float &var)
    {
        double tmpVar;
        int res = enif_get_double(env, term, &tmpVar);
        var = static_cast<float>(tmpVar);
        return res;
    }
    inline TERM make(ErlNifEnv *env, const float var)
    {
        return TERM(enif_make_double(env, static_cast<double>(var)));
    }
    /**
     * @brief 
     * This class sets the max supported dims
     * Working with dims is hardcoded for faster conversions. 
     */
    class dims
    {
        public:
        int x;
        int y;
        int z;
        int xyz;

        template<typename Type>
        dims(const std::vector<Type> &dimsVec)
        {
            enum {DIMS_X_IDX,DIMS_Y_IDX,DIMS_Z_IDX,DIMS_TOTAL};
            if(dimsVec.size() == DIMS_TOTAL)
            {
                x = static_cast<int>(dimsVec[DIMS_X_IDX]);
                y = static_cast<int>(dimsVec[DIMS_Y_IDX]);
                z = static_cast<int>(dimsVec[DIMS_Z_IDX]);
                xyz = x * y * z;
            }
        }
        dims(int dimX = 1, int dimY =1, int dimZ =1): x(dimX), y(dimY), z(dimZ) { xyz = x * y * z; };
        int totalDimsSize() { return xyz; }
    };

    template<typename Type>
    using Tensor3D = Eigen::Tensor<Type,MAX_SUPPORTED_DIMS>;
    template<typename Type> //
    using Tensor2D = Eigen::Tensor<Type,2>; //
    template<typename Type> //
    using Tensor1D = Eigen::Tensor<Type,1>; //

    template<typename Type> int getTensor3D(ErlNifEnv *env, ERL_NIF_TERM term, std::shared_ptr<Tensor3D<Type>> & tensor);
    template<typename Type> int getTensor2D(ErlNifEnv *env, ERL_NIF_TERM term, std::shared_ptr<Tensor2D<Type>> & tensor); //
    template<typename Type> int getTensor1D(ErlNifEnv *env, ERL_NIF_TERM term, std::shared_ptr<Tensor1D<Type>> & tensor); //
    template<typename Type> TERM makeTensor(ErlNifEnv *env, const Tensor3D<Type> &tensor);


    /**
     * @brief 
     * 
     * term template is an erlange list 
     * 
     * @tparam Type 
     * @tparam Dims 
     * @param env 
     * @param term - Erlang list as follows: [DimX,DimY,DimZ,Flat-Data] all floats
     * @param tensorPtr 
     * @return int 
     */
    template<typename Type> int getTensor3D(ErlNifEnv *env, ERL_NIF_TERM term, std::shared_ptr<Tensor3D<Type>> & tensor)   /// 3D
    {
        unsigned len;
        Type var;
        if(!enif_is_list(env, term)) return 0;
        int ret = enif_get_list_length(env, term, &len);
        if(!ret) return 0;
              
        ERL_NIF_TERM head, tail;
        tail = term; //very important to initalize the tail as whole list

        // Dimensions Read 
        std::vector<int> dimsVector(MAX_SUPPORTED_DIMS);
        //std::cout<<"A"<<std::endl;
        for(int i=0; i<MAX_SUPPORTED_DIMS; i++)
        {
            if (enif_get_list_cell(env, tail, &head, &tail))
            {
                if(!get(env, head, var)) 
                {

                    std::cout<<"get Error"<<std::endl;
                    return 0;
                }
                //std::cout<<"var dims: "<<var<<std::endl;
                dimsVector[i] = static_cast<int>(var);
            }
            else
            {
                throw std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
            }
        }
        //std::cout<<"B"<<std::endl;
        dims tensorDims(dimsVector);
        if ((len - MAX_SUPPORTED_DIMS) != tensorDims.xyz) // length = numOfDims + x*y*z
        {
            throw std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
        }
        //TODO optimization 
        std::shared_ptr<Tensor3D<Type>> newTensor = std::make_shared<Tensor3D<Type>>(tensorDims.xyz,1,1); // we start with a flat tensor to copy the data easily
                //std::cout<<"tensorDims.xyz: "<<tensorDims.xyz<<std::endl;

        for(int idx = 0; idx < tensorDims.xyz; idx++) //copy flat tensor 
        {
            if(enif_get_list_cell(env, tail, &head, &tail))
            {

                Type var;
                if(!get(env, head, var)) return 0; // conversion failure
                
                (*newTensor)(idx) = var;//TODO optimization 
                //std::cout<<"idx "<<idx<<" var: "<<newTensor(idx) <<std::endl;

            }
            else
            {
                throw  std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
            }
        }
        Eigen::array<int, 3> dimsArray{{tensorDims.x,tensorDims.y,tensorDims.z}};
        //reshape 
        //std::cout<<"before rehsape"<<std::endl;
        (*newTensor).reshape(dimsArray);
        //std::cout<<"after rehsape"<<std::endl;
        tensor = newTensor;
        return 1;
    }







    template<typename Type> int getTensor2D(ErlNifEnv *env, ERL_NIF_TERM term, std::shared_ptr<Tensor2D<Type>> & tensor)   /// 3D
    {
        unsigned len;
        Type var;
        if(!enif_is_list(env, term)) return 0;
        int ret = enif_get_list_length(env, term, &len);
        if(!ret) return 0;
              
        ERL_NIF_TERM head, tail;
        tail = term; //very important to initalize the tail as whole list

        // Dimensions Read 
        std::vector<int> dimsVector(MAX_SUPPORTED_DIMS);
        //std::cout<<"A"<<std::endl;
        for(int i=0; i<MAX_SUPPORTED_DIMS; i++)
        {
            if (enif_get_list_cell(env, tail, &head, &tail))
            {
                if(!get(env, head, var)) 
                {

                    std::cout<<"get Error"<<std::endl;
                    return 0;
                }
                //std::cout<<"var dims: "<<var<<std::endl;
                dimsVector[i] = static_cast<int>(var);
            }
            else
            {
                throw std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
            }
        }
        //std::cout<<"B"<<std::endl;
        dims tensorDims(dimsVector);
        if ((len - MAX_SUPPORTED_DIMS) != tensorDims.xyz) // length = numOfDims + x*y*z
        {
            throw std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
        }
        //TODO optimization
         std::shared_ptr<Tensor2D<Type>> newTensor = std::make_shared<Tensor2D<Type>>(tensorDims.x,tensorDims.y); // we start with a 2D tensor to copy the data

        //std::shared_ptr<Tensor2D<Type>> newTensor = std::make_shared<Tensor2D<Type>>(tensorDims.xyz,1); // using reshape 
                //std::cout<<"tensorDims.xyz: "<<tensorDims.xyz<<std::endl;

        for(int idx = 0; idx < tensorDims.xyz; idx++) //copy flat tensor 
        {
            if(enif_get_list_cell(env, tail, &head, &tail))
            {

                Type var;
                if(!get(env, head, var)) return 0; // conversion failure

                //(*newTensor)(idx) = var;// using reshape
               
                (*newTensor)(idx/tensorDims.y , idx%tensorDims.y) = var;//TODO optimization 
                //std::cout<<"idx "<<idx<<" var: "<<newTensor(idx/tensorDims.y , idx%tensorDims.y) <<std::endl;

            }
            else
            {
                throw  std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
            }
        }
        
        Eigen::array<int, 2> dimsArray({tensorDims.x,tensorDims.y});
        
        //std::cout<<"before rehsape"<<std::endl;
        //(*newTensor).reshape(dimsArray);
        //cout << newTensor->dimension(0) << endl; 
        //cout << newTensor->dimension(1) << endl; 
        //std::cout<<"after rehsape"<<std::endl;
        //dimst = dimsArray2;

        //std::cout<<"before rehsape"<<std::endl;
        //newTensor.reshape(dimsArray);
        //std::cout<<"after rehsape"<<std::endl;

        tensor = newTensor;


        return 1;
    }






template<typename Type> int getTensor1D(ErlNifEnv *env, ERL_NIF_TERM term, std::shared_ptr<Tensor1D<Type>> & tensor) ///1D
    {
        unsigned len;
        Type var;
        if(!enif_is_list(env, term)) return 0;
        int ret = enif_get_list_length(env, term, &len);
        if(!ret) return 0;
              
        ERL_NIF_TERM head, tail;
        tail = term; //very important to initalize the tail as whole list

        // Dimensions Read 
        std::vector<int> dimsVector(MAX_SUPPORTED_DIMS);
        //std::cout<<"A"<<std::endl;
        for(int i=0; i<MAX_SUPPORTED_DIMS; i++)
        {
            if (enif_get_list_cell(env, tail, &head, &tail))
            {
                if(!get(env, head, var)) 
                {

                    std::cout<<"get Error"<<std::endl;
                    return 0;
                }
                //std::cout<<"var dims: "<<var<<std::endl;
                dimsVector[i] = static_cast<int>(var);
            }
            else
            {
                throw std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
            }
        }
        //std::cout<<"B"<<std::endl;
        dims tensorDims(dimsVector);
        if ((len - MAX_SUPPORTED_DIMS) != tensorDims.xyz) // length = numOfDims + x*y*z
        {
            throw std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
        }
        //TODO optimization 
        std::shared_ptr<Tensor<Type,1>> newTensor = std::make_shared<Tensor<Type,1>>(tensorDims.xyz); // we start with a flat tensor to copy the data easily
                //std::cout<<"tensorDims.xyz: "<<tensorDims.xyz<<std::endl;

        for(int idx = 0; idx < tensorDims.xyz; idx++) //copy flat tensor 
        {
            if(enif_get_list_cell(env, tail, &head, &tail))
            {

                Type var;
                if(!get(env, head, var)) return 0; // conversion failure
                
                (*newTensor)(idx) = var;//TODO optimization 
                //std::cout<<"idx "<<idx<<" var: "<<newTensor(idx) <<std::endl;

            }
            else
            {
                throw  std::runtime_error(EXCEPTION_STR_INVALID_ERL_TENSOR);
            }
        }
        tensor = newTensor;
        //std::cout<<"tensor1D ok"<<std::endl;

        return 1;
    }




//TODO check this function
    template<typename Type> nifpp::TERM makeTensor(ErlNifEnv *env, const Tensor3D<Type> &tensor)
    {
        const auto& d = tensor.dimensions();
        std::vector<Type> listRepresentation(&d[0], d.data() + MAX_SUPPORTED_DIMS);
        dims tensDims(listRepresentation);
        std::vector<Type> tensorVec(tensor.data(), tensor.data()+tensDims.xyz);
        listRepresentation.insert( listRepresentation.end(), 
                                   std::make_move_iterator(tensorVec.begin()), std::make_move_iterator(tensorVec.end()));

        return make(env,listRepresentation);
    }

    template<typename Type> nifpp::TERM makeTensor2D(ErlNifEnv *env, const Tensor2D<Type> &tensor)
    {
        int x,y;
        const auto& d = tensor.dimensions();
        std::vector<Type> listRepresentation(&d[0], d.data() + 3);
        listRepresentation[2] = 1;
        //dims tensDims(listRepresentation);
        x = static_cast<int>(listRepresentation[0]);
        y = static_cast<int>(listRepresentation[1]);
        
        std::vector<Type> tensorVec(tensor.data(), tensor.data()+ (x*y)  );
        listRepresentation.insert( listRepresentation.end(), 
                                   std::make_move_iterator(tensorVec.begin()), std::make_move_iterator(tensorVec.end()));

        return make(env,listRepresentation);
    }

    template<typename Type> nifpp::TERM makeTensor1D(ErlNifEnv *env, const Tensor1D<Type> &tensor)
    {
        int x;
        const auto& d = tensor.dimensions();
    
        ;
        std::vector<Type> listRepresentation(&d[0], &d[0] + 3);
        listRepresentation[1] = 1;
        listRepresentation[2] = 1;
        //dims tensDims(listRepresentation);
        x = static_cast<int>(listRepresentation[0]);
        
        std::vector<Type> tensorVec(tensor.data(), tensor.data()+ x  );
        listRepresentation.insert( listRepresentation.end(), 
                                   std::make_move_iterator(tensorVec.begin()), std::make_move_iterator(tensorVec.end()));
        
       
        return make(env,listRepresentation);
    }
}