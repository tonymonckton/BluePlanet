using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode][ExecuteAlways]
public class rotateGameObject : MonoBehaviour
{
    public float xAngle = 0.0f;
    public float yAngle = 1.0f;
    public float zAngle = 0.0f;
    public float speed = 2.0f;

    void Update()
    {
        transform.Rotate(xAngle*speed*Time.deltaTime, yAngle*speed*Time.deltaTime, zAngle*speed*Time.deltaTime);
    }

}
